//
//  ViewController.m
//  RealmCrash
//
//  Created by Aleksey Garbarev on 18/08/16.
//  Copyright (c) 2016 AppsQuick.ly. All rights reserved.
//


#import "ViewController.h"
#import "RLMRealm.h"
#import "RLMRealmConfiguration.h"
#import "Person.h"
#import "MBFakerName.h"
#import "MBFaker.h"
#import "PersonCell.h"
#import <Realm/Realm.h>


@interface ViewController ()

@end

@implementation ViewController {
    RLMResults<Person *> *_listData;

    RLMNotificationToken *_token;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self setupRealm];
    
    [self generateSampleData];
    
    [self setupTableUI];
    
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    
    [self simulateUpdateAndDeleteWhileMainThreadFrozen];
    
}

- (void)setupRealm
{
    NSLog(@"DatabasePath: %@", [[RLMRealmConfiguration defaultConfiguration] fileURL] );

    [RLMRealmConfiguration defaultConfiguration].deleteRealmIfMigrationNeeded = YES;
    
    NSLog(@"Configured realm: %@", [RLMRealm defaultRealm]);
}

- (void)generateSampleData
{
    for (int i = 0; i < 200; i += 1) {
        Person *person = [Person new];
        person.identifier = i;
        person.firstName = [MBFakerName firstName];
        person.lastName = [MBFakerName lastName];
        NSInteger age = (int)arc4random_uniform(50) + 15;
        person.age = @(age);

        [[RLMRealm defaultRealm] transactionWithBlock:^{
            [[RLMRealm defaultRealm] addOrUpdateObject:person];
        }];
    }
}

- (void)setupTableUI
{
    
    _listData = [[Person allObjects] sortedResultsUsingProperty:@"identifier" ascending:YES];

    __weak __typeof (self.tableView) weakTableView = self.tableView;
    _token = [_listData addNotificationBlock:^(RLMResults<Person *> *results, RLMCollectionChange *change, NSError *error) {
        [weakTableView reloadData];
    }];

    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self.tableView registerClass:[PersonCell class] forCellReuseIdentifier:@"PersonCell"];
    [self.tableView reloadData];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    PersonCell *cell = [tableView dequeueReusableCellWithIdentifier:@"PersonCell" forIndexPath:indexPath];

    Person *person = _listData[indexPath.row];

    [cell setPerson:person];

    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [_listData count];
}

- (void)simulateUpdateAndDeleteWhileMainThreadFrozen
{
    if (_listData.count == 0) {
        return;
    }
    
    int firstIdentifier = _listData.firstObject.identifier;
    NSInteger rowsInScreen = [self.tableView.indexPathsForVisibleRows count];


    //Wait for all cells to be initialized and KVO-subscribed
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
       
        // lock main thread, so RunLoop is paused while we doing background updates
        [self freezeMainThreadFor:1];

        NSMutableOrderedSet *identifiers = [NSMutableOrderedSet new];
        
        for (int i = firstIdentifier; i < firstIdentifier + rowsInScreen; i += 1) {
            [identifiers addObject:@(i)];
        }
        
        // Trigger KVO updates by updating names..
        
        for (NSNumber *identifier in identifiers) {
            [[RLMRealm defaultRealm] transactionWithBlock:^{
                Person *person = [Person objectForPrimaryKey:identifier];
                if (person) {
                    person.firstName = [MBFakerName firstName];
                    person.lastName = [MBFakerName lastName];
                }
                [[RLMRealm defaultRealm] addOrUpdateObject:person];
            }];
        }
        
        
        
        // Delete all objects from above, so KVO observers gets invaldated object
        for (NSNumber *identifier in identifiers) {
            [[RLMRealm defaultRealm] transactionWithBlock:^{
                Person *person = [Person objectForPrimaryKey:identifier];
                if (person) {
                    [[RLMRealm defaultRealm] deleteObject:person];
                }
            }];
        }
        
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self simulateUpdateAndDeleteWhileMainThreadFrozen];
        });
        
    });
}

- (void)freezeMainThreadFor:(NSTimeInterval)timeInterval
{
    dispatch_async(dispatch_get_main_queue(), ^{
        dispatch_semaphore_t sem = dispatch_semaphore_create(0);
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(timeInterval * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            dispatch_semaphore_signal(sem);
        });
        
        dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
        [self.tableView reloadData];
        [[RLMRealm defaultRealm] refresh];
    

    });
}

@end