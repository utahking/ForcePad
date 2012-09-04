/* 
 * Copyright (c) 2011, salesforce.com, inc.
 * Author: Jonathan Hersh jhersh@salesforce.com
 * All rights reserved.
 * 
 * Redistribution and use in source and binary forms, with or without modification, are permitted provided 
 * that the following conditions are met:
 * 
 *    Redistributions of source code must retain the above copyright notice, this list of conditions and the 
 *    following disclaimer.
 *  
 *    Redistributions in binary form must reproduce the above copyright notice, this list of conditions and 
 *    the following disclaimer in the documentation and/or other materials provided with the distribution. 
 *    
 *    Neither the name of salesforce.com, inc. nor the names of its contributors may be used to endorse or 
 *    promote products derived from this software without specific prior written permission.
 *  
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED 
 * WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A 
 * PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR 
 * ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED 
 * TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) 
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING 
 * NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
 * POSSIBILITY OF SUCH DAMAGE.
 */

#import "DateTimePicker.h"
#import "SFVUtil.h"
#import "SFVAsync.h"
#import "SFVAppCache.h"

@interface DateTimePicker (Private)
- (void) pickerDateChanged:(UIDatePicker *)sender;
- (void) clearDatePicker:(id)sender;
- (void) setTimeToNow:(id)sender;
@end

@implementation DateTimePicker

@synthesize dateTimeDelegate, allowsClearingFieldValue;

+ (DateTimePicker *)dateTimePickerWithField:(NSString *)field onRecord:(NSDictionary *)record {
    if( !field || !record )
        return nil;
        
    UIViewController *pickerVC = [[UIViewController alloc] init];
    DateTimePicker *nav = [[DateTimePicker alloc] initWithRootViewController:pickerVC];
    nav.allowsClearingFieldValue = NO;
    
    UIDatePicker *picker = [[[UIDatePicker alloc] init] autorelease];
    [picker setDate:[SFVUtil dateFromSOQLDatetime:[record objectForKey:field]]
           animated:NO];
    [picker addTarget:nav
               action:@selector(pickerDateChanged:)
     forControlEvents:UIControlEventValueChanged];
    
    if( [[[SFVAppCache sharedSFVAppCache] field:field 
                                       onObject:[record objectForKey:kObjectTypeKey]
                                 stringProperty:FieldType] isEqualToString:@"date"] 
        || ( [[record objectForKey:kObjectTypeKey] isEqualToString:@"Event"]
            && [[record objectForKey:@"IsAllDayEvent"] boolValue] 
            && [[NSArray arrayWithObjects:@"StartDateTime", @"EndDateTime", nil] containsObject:field] ) )
        [picker setDatePickerMode:UIDatePickerModeDate];
    else
        [picker setDatePickerMode:UIDatePickerModeDateAndTime];
    
    nav.picker = picker;

    pickerVC.view = picker;   
    pickerVC.contentSizeForViewInPopover = [picker sizeThatFits:CGSizeZero];
    pickerVC.title = [[SFVAppCache sharedSFVAppCache] field:field
                                                   onObject:[record objectForKey:kObjectTypeKey]
                                             stringProperty:FieldLabel];
    
    [pickerVC release];
    
    return [nav autorelease];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
        
    if( self.allowsClearingFieldValue )
        self.navigationBar.topItem.rightBarButtonItem = [[[UIBarButtonItem alloc] 
                                initWithBarButtonSystemItem:UIBarButtonSystemItemTrash
                                                     target:self
                                                     action:@selector(clearDatePicker:)] autorelease];
    
    self.navigationBar.topItem.leftBarButtonItem = [[[UIBarButtonItem alloc]
                                                     initWithTitle:(self.picker.datePickerMode == UIDatePickerModeDate
                                                                    ? NSLocalizedString(@"Today", @"Today")
                                                                    : NSLocalizedString(@"Now", @"Now"))
                                                     style:UIBarButtonItemStyleBordered
                                                     target:self
                                                     action:@selector(setTimeToNow:)] autorelease];
}

- (void)viewDidUnload {
    self.dateTimeDelegate = nil;
    self.picker = nil;
    [super viewDidUnload];
}

- (void)dealloc {
    [super dealloc];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	return YES;
}

#pragma mark - picker action

- (void)setTimeToNow:(id)sender {    
    [self.picker setDate:[NSDate date]
                animated:YES];
    
    [self pickerDateChanged:self.picker];
}

- (void)pickerDateChanged:(UIDatePicker *)sender {
    if( self.dateTimeDelegate && [self.dateTimeDelegate respondsToSelector:@selector(dateTimePicker:didChangeToDate:)] )
        [self.dateTimeDelegate dateTimePicker:self didChangeToDate:[sender date]];
}

- (void)clearDatePicker:(id)sender {
    if( self.dateTimeDelegate && [self.dateTimeDelegate respondsToSelector:@selector(dateTimePickerDidClearFieldValue:)] )
        [self.dateTimeDelegate dateTimePickerDidClearFieldValue:self];
}

@end
