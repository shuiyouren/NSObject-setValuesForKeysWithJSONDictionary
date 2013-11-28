//
//  NSObject+setValuesForKeysWithJSONDictionary.h
//  SafeSetDemo
//
//  Created by Tom Harrington on 12/29/11.
//  Copyright (c) 2011 Atomic Bird, LLC. All rights reserved.
//
//  Modify by shuiyouren on 11/26/13

#import <Foundation/Foundation.h>

@interface NSObject (setValuesForKeysWithJSONDictionary)

- (void)setValuesForKeysWithJSONDictionary:(NSDictionary *)keyedValues dateFormatter:(NSDateFormatter *)dateFormatter;

/**
 *the dic for array property name and class name, for example \
  @{"propertyName1":"propertyClassName1","propertyName2":"propertyClassName2"};
 */
- (NSDictionary *)dicForArraykeyAndClass __attribute__((pure))  __attribute__((unused));

@end