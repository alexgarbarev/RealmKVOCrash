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

    [self simulateFrequentlyBackgroundUpdates];
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

- (void)simulateFrequentlyBackgroundUpdates
{
    NSOperationQueue *queue = [NSOperationQueue new];
    queue.maxConcurrentOperationCount = 4;


    for (int i = 0; i < 100; i++) {
        __weak __typeof (self) weakSelf = self;
        double delayInSeconds = 0.2 * i;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [queue addOperationWithBlock:^{
                [weakSelf runRandomChange];
            }];
        });
    }
}


- (void)runRandomChange
{
    // Update existing persons
    [[RLMRealm defaultRealm] transactionWithBlock:^{
        int personsToUpdate = arc4random_uniform(20);
        for (int i = 0; i < personsToUpdate; i += 1) {
            Person *person = [Person objectForPrimaryKey:@(arc4random_uniform(200))];
            if (person) {
                person.firstName = [MBFakerName firstName];
                person.lastName = [MBFakerName lastName];
                NSLog(@"%d updated", person.identifier);
            }
        }
    }];

    // Delete persons
    [[RLMRealm defaultRealm] transactionWithBlock:^{
        int personsToDelete = arc4random_uniform(20);
        for (int i = 0; i < personsToDelete; i += 1) {
            Person *person = [Person objectForPrimaryKey:@(arc4random_uniform(200))];
            if (person) {
                NSLog(@"will delete %d", person.identifier);
                [[RLMRealm defaultRealm] deleteObject:person];
            }
        }
    }];

    // Insert or update persons
    [[RLMRealm defaultRealm] transactionWithBlock:^{
        int personsToAdd = arc4random_uniform(20);
        for (int i = 0; i < personsToAdd; i += 1) {
            Person *person = [Person new];
            person.identifier = arc4random_uniform(200);
            person.firstName = [MBFakerName firstName];
            person.lastName = [MBFakerName lastName];
            [[RLMRealm defaultRealm] addOrUpdateObject:person];
            NSLog(@"%d added", person.identifier);
        }
    }];
}


@end