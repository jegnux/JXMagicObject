//
//  JXMagicObject.m
//  JXMagicObject - https://github.com/JegnuX/JXMagicObject
//
//  Created by Jérôme Alves on 09/07/12.
//  Copyright (c) 2012 Jérôme Alves.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

#import <objc/runtime.h>
#import "JXMagicObject.h"

#pragma mark -
#pragma mark - JXProperty

@interface JXProperty : NSObject
{
    objc_property_t property;
}

+ (NSArray *) allPropertiesForClass:(Class)class;

+ (id) propertyForClass:(Class)class withName:(NSString *)name;
+ (id) propertyWithObjcProperty:(objc_property_t) objc_property;

- (id) initWithObjCProperty:(objc_property_t)objc_property;

- (NSString *) name;
- (NSArray *) attributes;

- (NSString *) getterString;
- (NSString *) setterString;

- (SEL) getter;
- (SEL) setter;

- (Ivar) IvarForObject:(id)object;

- (BOOL) isReadonly;
- (BOOL) isDynamic;

- (BOOL) isAssign;
- (BOOL) isRetain;
- (BOOL) isCopy;

- (NSString *) returnTypeString;
- (const char *) returnType;
- (NSString *) returnClassString;
- (Class) returnClass;

@end

@implementation JXProperty

+ (NSArray *) allPropertiesForClass:(Class)class;
{
    NSArray *classProperties;
    
    unsigned int outCount, i;
    objc_property_t *objc_properties = class_copyPropertyList(class, &outCount);
    
    NSMutableArray *returnArray = [[NSMutableArray alloc] initWithCapacity:outCount];
    
    for (i = 0; i < outCount; i++) {
        objc_property_t property = objc_properties[i];
        
        [returnArray addObject:[JXProperty propertyWithObjcProperty:property]];
    }
    
    classProperties = [NSArray arrayWithArray:returnArray];
    [returnArray release];
    
    return classProperties;
}

+ (id) propertyForClass:(Class)class withName:(NSString *)name
{
    objc_property_t property = class_getProperty(class, [name cStringUsingEncoding:NSUTF8StringEncoding]);
    return [JXProperty propertyWithObjcProperty:property];
}

+ (id) propertyWithObjcProperty:(objc_property_t) objc_property
{
    return [[[JXProperty alloc] initWithObjCProperty:objc_property] autorelease];
}

- (id) initWithObjCProperty:(objc_property_t)objc_property
{
    if (!objc_property)
        return nil;
    
    self = [super init];
    if (self) {
        property = objc_property;
    }
    return self;
}

- (NSString *) name
{
    return [NSString stringWithCString:property_getName(property)
                              encoding:NSUTF8StringEncoding];
}

- (NSString *) description
{
    return [NSString stringWithCString:property_getAttributes(property)
                              encoding:NSUTF8StringEncoding];
}


- (NSArray *)attributes
{
    return [[self description] componentsSeparatedByString:@","];
}


- (Ivar) IvarForObject:(id)object
{
    return object_getInstanceVariable(object, [[self name] cStringUsingEncoding:NSUTF8StringEncoding], nil);
}


- (NSString *) getterString
{
    NSString *getterString = [self name];
    
    for (NSString *attribute in [self attributes]) {
        NSString *firstCharacter = [attribute substringToIndex:1];
        if ([firstCharacter isEqualToString:@"G"]) {
            getterString = [attribute substringFromIndex:1];
            break; // Break because it's the true getter, no need to go further.
        }
    }
    
    return getterString;
}

- (NSString *) setterString
{
    NSString *setterString = [self name];
    
    for (NSString *attribute in [self attributes]) {
        NSString *firstCharacter = [attribute substringToIndex:1];
        if ([firstCharacter isEqualToString:@"S"]) {
            setterString = [attribute substringFromIndex:1];
            break; // Break because it's the true setter, no need to go further.
        }
    }
    
    if ([setterString rangeOfString:@":"].location == NSNotFound) { // true setter was not found so ":" is missing.
        setterString = [NSString stringWithFormat:@"set%@%@:",[[setterString substringToIndex:1] uppercaseString], [setterString substringFromIndex:1]];
    }
    
    return setterString;
}

- (SEL) getter
{
    return NSSelectorFromString([self getterString]);
}

- (SEL) setter
{
    return NSSelectorFromString([self setterString]);
}

- (BOOL) isReadonly
{
    return [[self attributes] containsObject:@"R"];
}

- (BOOL) isDynamic
{
    return [[self attributes] containsObject:@"D"];
}

#pragma mark - Membership

- (BOOL) isAssign
{
    return ([self isRetain] == NO && [self isCopy] == NO);
}

- (BOOL) isRetain
{
    return [[self attributes] containsObject:@"&"];
}

- (BOOL) isCopy
{
    return [[self attributes] containsObject:@"C"];
}

#pragma mark - Return Info

- (NSString *) returnTypeString
{
    for (NSString *attribute in [self attributes]) {
        NSString *firstCharacter = [attribute substringToIndex:1];
        
        if ([firstCharacter isEqualToString:@"T"]) {
            return [attribute substringFromIndex:1];
        }
    }
    return nil;
}

- (const char *) returnType
{
    return [[self returnTypeString] cStringUsingEncoding:NSUTF8StringEncoding];
}

- (NSString *) returnClassString
{
    NSString *classString = nil;
    for (NSString *attribute in [self attributes]) {
        if ([attribute length] < 2)
            continue;
        
        NSString *firstCharacters = [attribute substringToIndex:2];
        
        if ([firstCharacters isEqualToString:@"T@"]) {
            classString = [[attribute substringFromIndex:2] stringByTrimmingCharactersInSet:[NSCharacterSet punctuationCharacterSet]];
            break;
        }
    }
    
    return classString;
}

- (Class) returnClass
{
    return NSClassFromString([self returnClassString]);
}

@end

#pragma mark -
#pragma mark - JXPropertyMapping

@interface JXPropertyMapping : NSObject

@property (nonatomic, retain) JXProperty *property;
@property (nonatomic, retain) NSString *dictionaryKey;
@property (nonatomic, assign) Class dictionaryClass;
@property (nonatomic, retain) NSValueTransformer *valueTransformer;

+ (JXPropertyMapping *) propertyMappingWithProperty:(JXProperty *)aKey
                                      dictionaryKey:(NSString *)anOtherKey
                                    dictionaryClass:(Class)aClass
                                   valueTransformer:(NSValueTransformer *)aValueTransformer;


- (void) getPropertyValue:(id *)propertyValue fromDictionaryValue:(id *)dictionaryPointerValue;
- (void) getDictionaryValue:(id *)dictionaryValue fromPropertyValue:(id *)pointerPropertyValue;

@end

@implementation JXPropertyMapping

@synthesize property, dictionaryKey, dictionaryClass, valueTransformer;

+ (JXPropertyMapping *) propertyMappingWithProperty:(JXProperty *)aProperty
                                      dictionaryKey:(NSString *)aKey
                                    dictionaryClass:(Class)aClass
                                   valueTransformer:(NSValueTransformer *)aValueTransformer
{
    JXPropertyMapping *propertyMapping = [[JXPropertyMapping alloc] init];
    propertyMapping.property = aProperty;
    propertyMapping.dictionaryKey = aKey;
    propertyMapping.dictionaryClass = aClass;
    propertyMapping.valueTransformer = aValueTransformer;
    return [propertyMapping autorelease];
}

- (void) getPropertyValue:(id *)propertyValue fromDictionaryValue:(id *)dictionaryPointerValue
{
    id dictionaryValue = *dictionaryPointerValue;
    
    Class asDictionaryClass = [dictionaryValue class];
    Class asObjectClass = [self.property returnClass];
    const char *asObjectType = [self.property returnType];
  
    NSArray *validNumberTypes = [NSArray arrayWithObjects:@"c", @"C", @"s", @"S", @"i", @"I", @"l", @"L", @"q", @"Q", @"f", @"d", nil];
    NSString *asObjectTypeString = [NSString stringWithCString:asObjectType encoding:NSUTF8StringEncoding];

    if (self.valueTransformer) {
        *propertyValue = [self.valueTransformer transformedValue:dictionaryValue];
    }
    else if ([asDictionaryClass isSubclassOfClass:[NSArray class]] && [asObjectClass isSubclassOfClass:[NSArray class]]) {
        *propertyValue = dictionaryValue;
    }
    else if ([asDictionaryClass isSubclassOfClass:[NSDictionary class]])
    {
        if ([asObjectClass isSubclassOfClass:[JXMagicObject class]])
            *propertyValue = [dictionaryValue asMagicObject:asObjectClass];

        else if ([asObjectClass isSubclassOfClass:[NSDictionary class]])
            *propertyValue = dictionaryValue;
    }
    
    else if ([asDictionaryClass isSubclassOfClass:[NSString class]])
    {
        if ([asObjectClass isSubclassOfClass:[NSString class]]) {
            *propertyValue = dictionaryValue;
        }
        else if ([asObjectClass isSubclassOfClass:[NSNumber class]] || [validNumberTypes containsObject:asObjectTypeString]) {
            
            if ([[dictionaryValue lowercaseString] isEqualToString:@"yes"] || [[dictionaryValue lowercaseString] isEqualToString:@"true"]) {
                *propertyValue = [NSNumber numberWithBool:YES];
            }
            else if ([[dictionaryValue lowercaseString] isEqualToString:@"no"] || [[dictionaryValue lowercaseString] isEqualToString:@"false"]) {
                *propertyValue = [NSNumber numberWithBool:NO];
            }
            else if ([dictionaryValue rangeOfString:@"."].location != NSNotFound) {
                *propertyValue = [NSNumber numberWithDouble:[dictionaryValue doubleValue]];
            }
            else {
                *propertyValue = [NSNumber numberWithInteger:[dictionaryValue integerValue]];
            }
            
            asDictionaryClass = [NSNumber class];
        }
        
        else if ([asObjectClass isSubclassOfClass:[NSURL class]]) {
            *propertyValue = [NSURL URLWithString:dictionaryValue];
        }
        else if ([asObjectClass isSubclassOfClass:[NSDate class]] && [dictionaryValue doubleValue]) {
            *propertyValue = [NSDate dateWithTimeIntervalSince1970:[dictionaryValue doubleValue]];
        }
    }
    
    
    if ([asDictionaryClass isSubclassOfClass:[NSNumber class]])
    {
        NSNumber *number = dictionaryValue;
        
        if ([asObjectClass isSubclassOfClass:[NSNumber class]]) {
            number = dictionaryValue;
        }
        else if ([asObjectClass isSubclassOfClass:[NSString class]]) {
            number = [NSString stringWithFormat:@"%f",[dictionaryValue doubleValue]];
        }
        else if ([asObjectClass isSubclassOfClass:[NSDate class]]) {
            number = [NSDate dateWithTimeIntervalSince1970:[dictionaryValue doubleValue]];
        }
        
        if ([validNumberTypes containsObject:asObjectTypeString]) {
            [number getValue:propertyValue];
        }
        else {
            *propertyValue = number;
        }
        
        [number release];
    }
    
    if (*propertyValue == nil && strncmp(asObjectType, @encode(BOOL), 1) != 0) // BOOL "NO" point on nil so...
    {
        NSString *reaseon = [NSString stringWithFormat:@"Doesn't know how to transform dictionary value for key \"%@\" (%@) to property value for key \"%@\" (%@). Please use a value transformer.",
                             self.dictionaryKey, NSStringFromClass(asDictionaryClass),
                             [self.property name], [self.property returnClass] ? [self.property returnClassString] : [self.property returnTypeString]];
        
        @throw [NSException exceptionWithName:@"JXInvalidProperty"
                                       reason:reaseon
                                     userInfo:nil];
    }

}

- (void) getDictionaryValue:(id *)dictionaryValue fromPropertyValue:(id *)pointerPropertyValue
{
    id propertyValue = *pointerPropertyValue;
    
    Class asDictionaryClass = self.dictionaryClass ? self.dictionaryClass : [NSString class];
    Class asObjectClass = [self.property returnClass];
    const char *asObjectType = [self.property returnType];

    id nullValue = [NSNull null];
    
    if (propertyValue == nil) {
        *dictionaryValue = nullValue;
    }
    else if (self.valueTransformer) {
        *dictionaryValue = [self.valueTransformer reverseTransformedValue:propertyValue];
    }
    else if ([asDictionaryClass isSubclassOfClass:[NSArray class]]){
        *dictionaryValue = [propertyValue asDictionaries];
    }
    else if ([asObjectClass isSubclassOfClass:[JXMagicObject class]]) {
        *dictionaryValue = [propertyValue dictionary];
    }
    else if ([asObjectClass isSubclassOfClass:[NSDictionary class]])
    {
        *dictionaryValue = propertyValue;
    }
    else if ([asDictionaryClass isSubclassOfClass:[NSNull class]]) {
        *dictionaryValue = nullValue;
    }
    else if ([asDictionaryClass isSubclassOfClass:[NSString class]])
    {
        if (asObjectClass) {
            if (dictionaryValue == nil)
                *dictionaryValue = @"";
            
            else if ([asObjectClass isSubclassOfClass:[NSString class]])
                *dictionaryValue = propertyValue;
            
            else if ([asObjectClass isSubclassOfClass:[NSNumber class]])
                *dictionaryValue = [propertyValue stringValue];
            
            else if ([asObjectClass isSubclassOfClass:[NSURL class]])
                *dictionaryValue = [propertyValue absoluteString];
            
            else if ([asObjectClass isSubclassOfClass:[NSDate class]])
                *dictionaryValue = [NSString stringWithFormat:@"%.0f",[propertyValue timeIntervalSince1970]];
        }
        
        else if (strncmp(asObjectType, @encode(int), 1) == 0) {
            *dictionaryValue = [[NSNumber numberWithInt:*((int *)pointerPropertyValue)] stringValue];
        }
        
        else if (strncmp(asObjectType, @encode(float), 1) == 0) {
            *dictionaryValue = [[NSNumber numberWithFloat:*((float *)pointerPropertyValue)] stringValue];
        }
        
        else if (strncmp(asObjectType, @encode(BOOL), 1) == 0) {
            *dictionaryValue = *((BOOL *)pointerPropertyValue) ? @"true" : @"false";
        }
        
        else if (strncmp(asObjectType, @encode(NSInteger), 1) == 0) {
            *dictionaryValue = [[NSNumber numberWithInteger:*((NSInteger *)pointerPropertyValue)] stringValue];
        }
        
        else if (strncmp(asObjectType, @encode(long long), 1) == 0) {
            *dictionaryValue = [[NSNumber numberWithLongLong:*((long long *)pointerPropertyValue)] stringValue];
        }
        
        else if (strncmp(asObjectType, @encode(double), 1) == 0) {
            *dictionaryValue = [[NSNumber numberWithDouble:*((double *)pointerPropertyValue)] stringValue];
        }
        
        else if (strncmp(asObjectType, @encode(const char *), 1) == 0) {
            *dictionaryValue = [NSString stringWithCString:(const char *)propertyValue encoding:NSUTF8StringEncoding];
        }

    }
    
    else if ([asDictionaryClass isSubclassOfClass:[NSNumber class]])
    {
        if (asObjectClass) {
            if ([asObjectClass isSubclassOfClass:[NSNumber class]])
                *dictionaryValue = propertyValue;
            
            else if ([asObjectClass isSubclassOfClass:[NSString class]])
                *dictionaryValue = [NSNumber numberWithDouble:[propertyValue doubleValue]];
            
            else if ([asObjectClass isSubclassOfClass:[NSDate class]])
                *dictionaryValue = [NSNumber numberWithDouble:[propertyValue timeIntervalSince1970]];
        }
        else if (strncmp(asObjectType, @encode(int), 1) == 0) {
            *dictionaryValue = [NSNumber numberWithInt:*((int *)pointerPropertyValue)];
        }
        
        else if (strncmp(asObjectType, @encode(float), 1) == 0) {
            *dictionaryValue = [NSNumber numberWithFloat:*((float *)pointerPropertyValue)];
        }
        
        else if (strncmp(asObjectType, @encode(BOOL), 1) == 0) {
            *dictionaryValue = [NSNumber numberWithBool:*((BOOL *)pointerPropertyValue)];
        }
        
        else if (strncmp(asObjectType, @encode(NSInteger), 1) == 0) {
            *dictionaryValue = [NSNumber numberWithInteger:*((NSInteger *)pointerPropertyValue)];
        }
        
        else if (strncmp(asObjectType, @encode(long long), 1) == 0) {
            *dictionaryValue = [NSNumber numberWithLongLong:*((long long *)pointerPropertyValue)];
        }
        
        else if (strncmp(asObjectType, @encode(double), 1) == 0) {
            *dictionaryValue = [NSNumber numberWithDouble:*((double *)pointerPropertyValue)];
        }
    }
}

- (NSString *)description
{
    if (self.valueTransformer)
        return [NSString stringWithFormat:@"<%@: %p> %@ => %@ using %@",
                NSStringFromClass([self class]), 
                self, 
                [self.property name], 
                self.dictionaryKey,
                NSStringFromClass([self.valueTransformer class])];
    
    else
        return [NSString stringWithFormat:@"<%@: %p> %@ => %@",NSStringFromClass([self class]), self, [self.property name], self.dictionaryKey];
}

- (void)dealloc
{
    [property release];
    [dictionaryKey release];
    [valueTransformer release];
    [super dealloc];
}
@end

#pragma mark -
#pragma mark - JXMagicObject

@interface JXMagicObject()

@property (nonatomic, retain) NSMutableArray *propertyMappings;

- (void) _addPropertyMapping:(JXPropertyMapping *)propertyMapping;
- (void) _performMappingsFromDictionary;

- (JXPropertyMapping *) _propertyMappingForPropertyKey:(NSString *)key;
- (JXPropertyMapping *) _propertyMappingForDictionaryKey:(NSString *)key;

@end

#pragma clang diagnostic ignored "-Wincomplete-implementation"
@implementation JXMagicObject
{
    BOOL shouldUpdateDictionary;
}

/* Private Accessors */
@synthesize propertyMappings;

/* Public Accessors */
@synthesize dictionary;


#pragma mark - Init

- (id)initWithDictionary:(NSDictionary *)aDictionary
{
    self = [super init];
    if (self) {

        propertyMappings = [[NSMutableArray alloc] init];
        dictionary = aDictionary ? [aDictionary mutableCopy] : [[NSMutableDictionary alloc] init];
        
        if ([self respondsToSelector:@selector(setupMappings)]) { // Implemented by subclasses.
            [self setupMappings]; 
        }
        
        [self _performMappingsFromDictionary];
    }
    return self;
}

#pragma mark - Setup

- (void) _performMappingsFromDictionary
{
    NSArray *classProperties = [JXProperty allPropertiesForClass:[self class]];
    for (JXProperty *property in classProperties) {
        
        NSString *name = [property name];
        
        JXPropertyMapping *propertyMapping = [self _propertyMappingForPropertyKey:name];
        
        if (!propertyMapping) {
            propertyMapping = [JXPropertyMapping propertyMappingWithProperty:property
                                                               dictionaryKey:name
                                                             dictionaryClass:[[dictionary objectForKey:name] class]
                                                            valueTransformer:nil];
            [self _addPropertyMapping:propertyMapping];
        }
    }
    
    
    NSDictionary *copy = [dictionary copy];
    
    for(NSString *key in copy) {
        JXPropertyMapping *propertyMapping = [self _propertyMappingForDictionaryKey:key];
        
        if ([propertyMapping.property isDynamic]) {
            continue;
        }
        
        Ivar Ivar = [propertyMapping.property IvarForObject:self];
        
        if (Ivar != nil)
        {
            id transformedObject = [self transformedValueForKey:key];
            id finalObject = transformedObject;
            
            if ([propertyMapping.property returnClass] != nil) {
                if ([propertyMapping.property isRetain]) {
                    finalObject = [transformedObject retain];
                } else if ([propertyMapping.property isCopy]) {
                    finalObject = [transformedObject copy];
                }
            }
            
            object_setIvar(self, Ivar, transformedObject);
        }
        else {
            NSLog(@"%@ is not Key-Value coding compliant for the key \"%@\".", NSStringFromClass([self class]), key);
        }
    }
    [copy release];
    
    shouldUpdateDictionary = YES;
}

- (NSDictionary *) dictionary
{
    if (shouldUpdateDictionary == NO)
        goto returnDictionary;
    
    NSArray *classProperties = [JXProperty allPropertiesForClass:[self class]];
        
    for (JXProperty *property in classProperties) {
        if ([property isDynamic])
            continue;
        
        Ivar Ivar = [property IvarForObject:self];
        NSString *key = [NSString stringWithCString:ivar_getName(Ivar)
                                           encoding:NSUTF8StringEncoding];
        
        JXPropertyMapping *propertyMapping = [self _propertyMappingForPropertyKey:key];
        
        
        if (!propertyMapping) {
            propertyMapping = [JXPropertyMapping propertyMappingWithProperty:property
                                                               dictionaryKey:key
                                                             dictionaryClass:[[dictionary objectForKey:key] class]
                                                            valueTransformer:nil];
            [self _addPropertyMapping:propertyMapping];
        }
        
        id transformedValue = object_getIvar(self, Ivar);
        [self setTransformedValue:transformedValue forKey:propertyMapping.dictionaryKey];        
    }
    
    shouldUpdateDictionary = NO;
    
returnDictionary:
    return [NSDictionary dictionaryWithDictionary:dictionary];
}

#pragma mark - Message Forwarding

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector
{
    NSArray *getters = [self.propertyMappings valueForKeyPath:@"@unionOfObjects.property.getterString"];
    NSArray *setters = [self.propertyMappings valueForKeyPath:@"@unionOfObjects.property.setterString"];
    
    NSString *selectorString = NSStringFromSelector(aSelector);
    
    if ([getters containsObject:selectorString]) {
        return [self methodSignatureForSelector:@selector(transformedValueForKey:)];
    }
    else if ([setters containsObject:selectorString]) {
        return [self methodSignatureForSelector:@selector(setTransformedValue:forKey:)];
    }
    
    return [super methodSignatureForSelector:aSelector];
}


- (void)forwardInvocation:(NSInvocation *)anInvocation
{
    NSArray *getters = [self.propertyMappings valueForKeyPath:@"@unionOfObjects.property.getterString"];
    NSArray *setters = [self.propertyMappings valueForKeyPath:@"@unionOfObjects.property.setterString"];
    
    NSString *selectorString = NSStringFromSelector(anInvocation.selector);
    
    if ([getters containsObject:selectorString]) {
        JXPropertyMapping *propertyMapping = [self.propertyMappings objectAtIndex:[getters indexOfObject:selectorString]];
        
        NSString *key = propertyMapping.dictionaryKey;
        
        [anInvocation setSelector:@selector(transformedValueForKey:)];
        [anInvocation setArgument:&key atIndex:2];

        [anInvocation invoke];
    }
    else if ([setters containsObject:selectorString]) {
        JXPropertyMapping *propertyMapping = [self.propertyMappings objectAtIndex:[setters indexOfObject:selectorString]];

        NSString *key = propertyMapping.dictionaryKey;

        [anInvocation setSelector:@selector(setTransformedValue:forKey:)];
        [anInvocation setArgument:&key atIndex:3];
        
        [anInvocation invoke];
    }
    else {
        [super forwardInvocation:anInvocation];
    }
}


#pragma mark - Accessing to property mappings

- (JXPropertyMapping *) _propertyMappingForPropertyKey:(NSString *)key
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"property.name == %@",key];
    return [[self.propertyMappings filteredArrayUsingPredicate:predicate] lastObject];
}

- (JXPropertyMapping *) _propertyMappingForDictionaryKey:(NSString *)key
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"dictionaryKey == %@",key];
    return [[self.propertyMappings filteredArrayUsingPredicate:predicate] lastObject];
}

#pragma mark - Mapping Methods

- (void) _addPropertyMapping:(JXPropertyMapping *)propertyMapping
{
    NSString *propertyName = [propertyMapping.property name];
    
    [self removePropertyMappingForPropertyKey:propertyName];
    
    [self addObserver:self forKeyPath:propertyName options:NSKeyValueObservingOptionNew context:nil];
    
    [self.propertyMappings addObject:propertyMapping];
}

- (void) removePropertyMappingForPropertyKey:(NSString *)propertyKey
{    
    JXPropertyMapping *propertyMapping = [self _propertyMappingForPropertyKey:propertyKey];
    if (propertyMapping) {
        [self removeObserver:self forKeyPath:propertyKey];
        [self.propertyMappings removeObject:propertyMapping];
    }
}

- (void) mapProperty:(NSString *)propertyKey toKey:(NSString *)dictionaryKey
{
    [self mapProperty:propertyKey toKey:dictionaryKey usingValueTransformer:nil];
}

- (void) mapProperty:(NSString *)propertyKey toKey:(NSString *)dictionaryKey usingValueTransformer:(NSValueTransformer *)valueTransformer
{
    JXPropertyMapping *propertyMapping = [JXPropertyMapping propertyMappingWithProperty:[JXProperty propertyForClass:[self class] withName:propertyKey]
                                                                          dictionaryKey:dictionaryKey
                                                                        dictionaryClass:[[dictionary objectForKey:dictionaryKey] class]
                                                                       valueTransformer:valueTransformer];
    [self _addPropertyMapping:propertyMapping];
}

#pragma mark - Utilities

- (Ivar) IvarForKey:(NSString *)key
{
    JXProperty *property = [JXProperty propertyForClass:[self class] withName:key];
    return [property IvarForObject:self];
}

- (SEL) getterForKey:(NSString *)key
{
    JXProperty *property = [JXProperty propertyForClass:[self class] withName:key];
    return [property getter];
}

- (SEL) setterForKey:(NSString *)key
{
    JXProperty *property = [JXProperty propertyForClass:[self class] withName:key];
    return [property setter];
}

#pragma mark - KVO/KVC

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([self _propertyMappingForPropertyKey:keyPath]) {
        shouldUpdateDictionary = YES;
    }
}

- (id) transformedValueForKey:(NSString *)key
{
    shouldUpdateDictionary = YES;
    JXPropertyMapping *propertyMapping = [self _propertyMappingForDictionaryKey:key];
    id dictionaryValue = [dictionary objectForKey:key];
    
    if (dictionaryValue) {
        id propertyValue = nil;
        [propertyMapping getPropertyValue:&propertyValue fromDictionaryValue:&dictionaryValue];
        return propertyValue;
    }
    
    return nil;
}

- (void) setTransformedValue:(id)propertyValue forKey:(NSString *)key
{
    shouldUpdateDictionary = YES;
    JXPropertyMapping *propertyMapping = [self _propertyMappingForDictionaryKey:key];

    id dictionaryValue = nil;
    [propertyMapping getDictionaryValue:&dictionaryValue fromPropertyValue:&propertyValue];
    [dictionary setValue:dictionaryValue forKey:propertyMapping.dictionaryKey];
}

#pragma mark - Memory Management

- (void)dealloc
{
    for (JXPropertyMapping *propertyMapping in propertyMappings) {
        [self removeObserver:self forKeyPath:[propertyMapping.property name]];
    }
    [dictionary release];
    [propertyMappings release];
    [super dealloc];
}

@end

@implementation NSDictionary (JXMagicObject)

- (JXMagicObject *) asMagicObject:(Class)magicObjectSubclass
{
    NSAssert1([magicObjectSubclass isSubclassOfClass:[JXMagicObject class]],@"%@ is not a JXMagicObjectSubclass.",NSStringFromClass(magicObjectSubclass));
    
    return [[[magicObjectSubclass alloc] initWithDictionary:self] autorelease];
}

@end

@implementation NSArray (JXMagicObject)

- (NSArray *) asMagicObjects:(Class)magicObjectSubclass
{
    NSAssert1([magicObjectSubclass isSubclassOfClass:[JXMagicObject class]],@"%@ is not a JXMagicObjectSubclass.",NSStringFromClass(magicObjectSubclass));
 
    NSMutableArray *mutableArray = [[NSMutableArray alloc] initWithCapacity:[self count]];
    
    for (id item in self) {
        if ([item isKindOfClass:[NSDictionary class]]) {
            [mutableArray addObject:[item asMagicObject:magicObjectSubclass]];
        }
    }
    
    NSArray *returnArray = [NSArray arrayWithArray:mutableArray];
    [mutableArray release];
    
    return returnArray;
}

- (NSArray *) asDictionaries
{    
    NSMutableArray *mutableArray = [[NSMutableArray alloc] initWithCapacity:[self count]];
    
    for (id item in self) {
        if ([item isKindOfClass:[JXMagicObject class]]) {
            [mutableArray addObject:[item dictionary]];
        }
    }
    
    NSArray *returnArray = [NSArray arrayWithArray:mutableArray];
    [mutableArray release];
    
    return returnArray;
}


@end
