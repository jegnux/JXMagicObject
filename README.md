JXMagicObject
=============

Magically map your dictionaries keys/values to a true object instance.

## Installation

#### Import
Just add JXMagicObject.h and JXMagicObject.m to your project.

####ARC
If you are including JXMagicObject in a project that uses Automatic Reference Counting (ARC) enabled, you will need to set the -fno-objc-arc compiler flag on the two source files. To do this in Xcode, go to your active target and select the "Build Phases" tab. Now select JXMagicObject.h and JXMagicObject.m source files, press Enter, insert -fno-objc-arc and then "Done" to disable ARC.


## How it works

At initialization JXMagicObject take all values from the dictionary and populate instance variable, accordingly to the map scheme.

If property key and dictionary key are the same, you have nothing to do, it just works.
But sometimes you want a property key different, for exemple if you don't like those underscore there is in the dictionary's keys. 

Just override **-setupMappings** and use **-mapProperty:toKey:**
```objective-c
[self mapProperty:@"favoriteNumber" toKey:@"favorite_number"];
```

### Dynamic vs Synthesized properties

Synthesized properties :
- At initialization : values are taken from dictionary and are put in instance variables.
- You can use your getters and setters as many time as you want, the dictionary will not be solicited.
- When you call -dictionary, values are taken from instance variables and are put back to the dictionary.
- They are great if you need to access often to your properties (using getters and setters), because the whole transform process will not be done until you call -dictionary.

For dynamic properties :
- There is no instance variables.
- Using getters is like sending a **-objectForKey:** message on the dictionary. Same thing for the setter and **-setObject:forKey:** – except that values are transformed.
- They are great if you need to access often to your dictionary, because the whole transform process will be done only if you use getters and setters.

### Value Transformers

JXMagicObject can automagically transform dictionary values to match your property declarations. You have nothing to do.
Supported classes are **NSString, NSNumber, NSArray, NSDictionary, NSURL,** and **NSDate** (if the value is a timestamp).

Supported types are : **int, float, double, BOOL, NSInteger, long, long long, NSInteger, CGFloat,** and **NSTimeInterval**.

Moreover if your property is a subclass of JXMagicObject, it will be automagically transformed too.


But if you want to use another kind of object (NSDate, NSData, UIImage, CGRect, whatever) you can use a [NSValueTransformer](http://developer.apple.com/library/mac/#documentation/Cocoa/Reference/Foundation/Classes/NSValueTransformer_Class/Reference/Reference.html) subclass and map your property using -mapProperty:toKey:usingValueTransformer:
```objective-c
    JXStringToDateValueTransformer *transformer = [JXStringToDateValueTransformer new];
    
    [self mapProperty:@"birthdate" toKey:@"birth_date" usingValueTransformer:transformer];
    
    [transformer release];
```

## Usage Example

#### Setup
Just subclass JXMagicObject and add your properties :

```objective-c
@interface JXUser : JXMagicObject

@property (nonatomic, assign) NSString *firstName;
@property (nonatomic, retain) NSString *lastName;
@property (nonatomic, retain) NSDate *birthdate;
@property (nonatomic, assign) NSInteger favoriteNumber;

@end
```

And write the implementation :

```objective-c
@implementation JXUser

@synthesize firstName, lastName, birthdate;

@dynamic favoriteNumber;

- (void)dealloc
{
    [firstName release];
    [lastName release];
    [birthdate release];
    [super dealloc];
}
@end
```

Then setup your mappings if needed by overriding **-setupMapings** :

```objective-c
// Setup mappings if :
- (void) setupMappings
{
    // keys are different
    [self mapProperty:@"firstName" toKey:@"name"];
    [self mapProperty:@"favoriteNumber" toKey:@"favorite_number"];

    // you need a specific transformation
    JXStringToDateValueTransformer *transformer = [[JXStringToDateValueTransformer alloc] init];
    
    [self mapProperty:@"birthdate" toKey:@"birth_date" usingValueTransformer:transformer];
    
    [transformer release];
}
```

#####Now You can use it :
```objective-c
        NSDictionary *userDict = [NSDictionary dictionaryWithObjectsAndKeys:
                                  @"Jerome", @"name",
                                  @"Alves", @"lastName",
                                  @"42", @"favorite_number",
                                  @"08/18/1989", @"birth_date", nil];

       JXUser *user = [[JXUser alloc] initWithDictionary:userDict];
 
        NSLog(@"%@ %@", user.firstName, user.lastName);
        user.favoriteNumber = 1337;
        user.birthDate = [NSDate date];
        
        NSLog(@"Dictionary : %@", [user dictionary]);
        
        [user release];
```
Output : 
```objective-c
Jerome Alves
Dictionary : {
    "birth_date" = "07/28/2012";
    "favorite_number" = 1337;
    lastName = Alves;
    name = "Jerome";
}
```

## License 
MIT License.

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.