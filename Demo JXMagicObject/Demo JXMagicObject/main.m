//
//  main.m
//  Demo JXMagicObject - https://github.com/JegnuX/JXMagicObject
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

#import <Foundation/Foundation.h>
#import "JXUser.h"

int main(int argc, const char * argv[])
{
    @autoreleasepool {
        
        NSDictionary *githubAccountDict = [NSDictionary dictionaryWithObjectsAndKeys:
                                           @"JegnuX", @"login",
                                           @"http://github.com/JegnuX/", @"url", nil];
        
        NSDictionary *userDict = [NSDictionary dictionaryWithObjectsAndKeys:
                                  @"Jérôme", @"name",
                                  @"Alves", @"lastName",
                                  @"42", @"favorite_number",
                                  @"08/18/1989", @"birth_date",
                                  [NSNumber numberWithBool:NO], @"hireable",
                                  githubAccountDict, @"githubAccount", nil];
        
        JXUser *user = [[JXUser alloc] initWithDictionary:userDict];

        NSLog(@"Initial Dictionary : %@", [user dictionary]);
        
        NSLog(@"%@ %@", user.firstName, user.lastName);
        NSLog(@"BirthDate : %@", user.birthdate);
        
        NSLog(@"Github Account : %@",user.githubAccount);
        NSLog(@"Github Account URL : %@",user.githubAccount.url);
        
        NSLog(@"Available ? %@",[user isHireable] ? @"YES" : @"NO");
        
        user.favoriteNumber = 1337;
        user.hireable = YES;
        user.birthdate = [NSDate date];
        
        NSLog(@"Available ? %@",[user isHireable] ? @"YES" : @"NO");
        
        user.githubAccount.currentRepository = @"JXMagicObject";
        
        NSLog(@"Final Dictionary : %@", [user dictionary]);
        
        [user release];
    }
    return 0;
}

