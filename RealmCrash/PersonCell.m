////////////////////////////////////////////////////////////////////////////////
//
//  APPSQUICK.LY
//  Copyright 2016 AppsQuick.ly Pty Ltd
//  All Rights Reserved.
//
//  NOTICE: Prepared by AppsQuick.ly on behalf of AppsQuick.ly. This software
//  is proprietary information. Unauthorized use is prohibited.
//
////////////////////////////////////////////////////////////////////////////////

#import "PersonCell.h"
#import "Person.h"


@implementation PersonCell
{
    Person *_person;
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier];
    if (self) {

    }

    return self;
}

- (void)unsubscribeKVO
{
    [_person removeObserver:self forKeyPath:@"firstName"];
    [_person removeObserver:self forKeyPath:@"lastName"];
    [_person removeObserver:self forKeyPath:@"invalidated"];
}

- (void)subscribeKVO
{
    [_person addObserver:self forKeyPath:@"firstName" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:NULL];
    [_person addObserver:self forKeyPath:@"lastName" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:NULL];
    [_person addObserver:self forKeyPath:@"invalidated" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:NULL];
}

- (void)dealloc
{
    [self unsubscribeKVO];
}

- (void)setPerson:(Person *)person
{
    if (_person) {
        [self unsubscribeKVO];
    }

    _person = person;

    [self updateLabels];

    [self subscribeKVO];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change
                       context:(void *)context
{
    if (_person.invalidated) {
        [self unsubscribeKVO];
        _person = nil;
    }
    [self updateLabels];
}

- (void)updateLabels
{
    self.textLabel.text = [NSString stringWithFormat:@"%d. %@", _person.identifier, _person.firstName];
    self.detailTextLabel.text = _person.lastName;
}


@end