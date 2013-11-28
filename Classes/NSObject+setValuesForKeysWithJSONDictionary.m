//
//  NSObject+setValuesForKeysWithJSONDictionary.m
//  SafeSetDemo
//
//  Created by Tom Harrington on 12/29/11.
//  Copyright (c) 2011 Atomic Bird, LLC. All rights reserved.
//

#import "NSObject+setValuesForKeysWithJSONDictionary.h"
#import <objc/runtime.h>

@implementation NSObject (setValuesForKeysWithJSONDictionary)

- (void)setValuesForKeysWithJSONDictionary:(NSDictionary *)keyedValues dateFormatter:(NSDateFormatter *)dateFormatter
{
	unsigned int propertyCount;
    objc_property_t *properties = NULL;
    
    unsigned int selfPropertyCount;
	objc_property_t *selfProperties = class_copyPropertyList([self class], &selfPropertyCount);
    objc_property_t *superProperties = NULL;
    
    Class superClass = class_getSuperclass([self class]);
    if (superClass != [NSObject class]) {
        unsigned int superPropertyCount;
        superProperties = class_copyPropertyList(superClass, &superPropertyCount);
        
        properties = malloc((selfPropertyCount+superPropertyCount)*sizeof(objc_property_t));
        if (properties != NULL) {
            memcpy(properties, selfProperties, selfPropertyCount*sizeof(objc_property_t));
            memcpy(properties+selfPropertyCount, superProperties, superPropertyCount*sizeof(objc_property_t));
        }
        
        propertyCount = selfPropertyCount+superPropertyCount;
    }
    else {
        properties = selfProperties;
        propertyCount = selfPropertyCount;
    }
	
	/*
	 This code iterates over self's properties instead of ivars because the backing ivar might have a different name
	 than the property, for example if the class includes something like:
	 
	 @synthesize foo = foo_;
	 
	 In this case what we really want is "foo", not "foo_", since the incoming keys in keyedValues probably
	 don't have the underscore. Looking through properties gets "foo", looking through ivars gets "foo_".
	 */
	for (int i=0; i<propertyCount; i++) {
		objc_property_t property = properties[i];
		const char *propertyName = property_getName(property);
		NSString *keyName = [NSString stringWithUTF8String:propertyName];
		
		id value = [keyedValues objectForKey:keyName];
		if (value != nil) {
			char *typeEncoding = NULL;
			typeEncoding = property_copyAttributeValue(property, "T");
			
			if (typeEncoding == NULL) {
				continue;
			}
			switch (typeEncoding[0]) {
				case '@':
				{
					// Object
					Class class = nil;
					if (strlen(typeEncoding) >= 3) {
						char *className = strndup(typeEncoding+2, strlen(typeEncoding)-3);
						class = NSClassFromString([NSString stringWithUTF8String:className]);
                        free(className);
					}
					// Check for type mismatch, attempt to compensate
					if ([class isSubclassOfClass:[NSString class]] && [value isKindOfClass:[NSNumber class]]) {
						value = [value stringValue];
					} else if ([class isSubclassOfClass:[NSNumber class]] && [value isKindOfClass:[NSString class]]) {
						// If the ivar is an NSNumber we really can't tell if it's intended as an integer, float, etc.
						NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
						[numberFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
						value = [numberFormatter numberFromString:value];
						[numberFormatter release];
					} else if ([class isSubclassOfClass:[NSDate class]] && [value isKindOfClass:[NSString class]] && (dateFormatter != nil)) {
						value = [dateFormatter dateFromString:value];
					}
                    
                    
                    /*****************************shuiyouren add*****************************/
                    else if ([class isSubclassOfClass:[NSString class]] && [value isKindOfClass:[NSArray class]] && value != nil && [value count] == 0) {
                        value = @"";
                    }
                    
                    else if ([class isSubclassOfClass:[NSArray class]] && value) {
                        if ([value count] == 0) {
                            value = nil;
                        }
                        if ([self respondsToSelector:@selector(dicForArraykeyAndClass)]) {
                            NSDictionary *tmpDic = [self performSelector:@selector(dicForArraykeyAndClass)];
                            NSString *newClassName = [tmpDic objectForKey:keyName];
                            Class newClass = NSClassFromString(newClassName);
                            if (newClass) {
                                int aArrCount = [value count];
                                NSMutableArray *tmpArr = [NSMutableArray arrayWithCapacity:aArrCount];
                                for (id aItem in value) {
                                    if ([aItem isKindOfClass:[NSDictionary class]]) {
                                        id aNewItem = [[newClass alloc] init];
                                        
                                        [aNewItem setValuesForKeysWithJSONDictionary:aItem dateFormatter:nil];
                                        
                                        [tmpArr addObject:aNewItem];
                                        [aNewItem release];
                                    }
                                    else {
                                        [NSException raise:@"Json parse error" format:@"the value %@ is not a dic", aItem];
                                    }
                                }
                                
                                value = tmpArr;
                            }
                            else {
                                [NSException raise:@"Json set parse dic error" format:@"not exist the class: %@", newClassName];
                            }
                        }
                        else {
                            [NSException raise:@"Json parse error" format:@"can not parse the array for key: %@,please implement function: -(NSDictionary *)dicForArraykeyAndClass", keyName];
                        }
                    }
                    
                    //custom class
                    else if (![class isSubclassOfClass:[NSString class]] && ![class isSubclassOfClass:[NSNumber class]] && ![class isSubclassOfClass:[NSDate class]]) {
                        id tmpItem = [[[class alloc] init] autorelease];
                        if (![value isKindOfClass:[NSDictionary class]]) {
                            [NSException raise:@"Json parse error" format:@"the value for key %@ is not a dic, value class: %@", keyName, NSStringFromClass([value class])];
                        }
                        [tmpItem setValuesForKeysWithJSONDictionary:value dateFormatter:nil];
                        
                        value = tmpItem;
                    }
                    
                    /************************************************************************/
                    
					
					break;
				}
					
				case 'i': // int
				case 's': // short
				case 'l': // long
				case 'q': // long long
				case 'I': // unsigned int
				case 'S': // unsigned short
				case 'L': // unsigned long
				case 'Q': // unsigned long long
				case 'f': // float
				case 'd': // double
				case 'B': // BOOL
				{
					if ([value isKindOfClass:[NSString class]]) {
						NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
						[numberFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
						value = [numberFormatter numberFromString:value];
						[numberFormatter release];
					}
					break;
				}
					
				case 'c': // char
				case 'C': // unsigned char
				{
					if ([value isKindOfClass:[NSString class]]) {
						char firstCharacter = [value characterAtIndex:0];
						value = [NSNumber numberWithChar:firstCharacter];
					}
					break;
				}
					
				default:
				{
					break;
				}
			}
			[self setValue:value forKey:keyName];
			free(typeEncoding);
		}
	}
	free(properties);
    free(selfProperties);
    free(superProperties);
}

@end