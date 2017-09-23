//
//  ViewController.m
//  SQliteStorage
//
//  Created by Naresh Kongara on 9/22/17.
//  Copyright © 2017 Naresh Kongara. All rights reserved.
//

#import "StorageViewController.h"
#import <sqlite3.h>

@interface StorageViewController ()

@property (strong, nonatomic) NSString *databasePath;
@property (nonatomic) sqlite3 *contactDB;

@property (weak, nonatomic) IBOutlet UITextField *name;
@property (weak, nonatomic) IBOutlet UITextField *location;
@property (weak, nonatomic) IBOutlet UITextView *address;
@property (weak, nonatomic) IBOutlet UITextField *phoneNumber;
@property (weak, nonatomic) IBOutlet UITextField *email;


@property (weak, nonatomic) IBOutlet UILabel *status;


@end

@implementation StorageViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [self createDBIfNeeded];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)saveContact:(id)sender {
    sqlite3_stmt    *statement;
    const char *dbpath = [self.databasePath UTF8String];
    
    if (sqlite3_open(dbpath, &_contactDB) == SQLITE_OK)
    {
        
        NSString *name = _name.text ?: @"";
        NSString *location = _location.text ?: @"";
        NSString *address = _address.text ?: @"";
        NSString *phone = _phoneNumber.text ?: @"";
        NSString *email = _email.text ?: @"";

        
        NSString *insertSQL = [NSString stringWithFormat:
                               @"INSERT INTO CONTACTS (name, location, address, phone, email) VALUES (\"%@\", \"%@\", \"%@\", \"%@\", \"%@\")",
                               name, location, address, phone, email];
        
        const char *insert_stmt = [insertSQL UTF8String];
        sqlite3_prepare_v2(_contactDB, insert_stmt,
                           -1, &statement, NULL);
        if (sqlite3_step(statement) == SQLITE_DONE)
        {
            _status.text = @"Contact added";
            _status.textColor = [UIColor greenColor];
            _name.text = @"";
            _address.text = @"";
            _location.text = @"";
            _phoneNumber.text = @"";
            _email.text = @"";
        } else {
            _status.text = @"Failed to add contact";
            _status.textColor = [UIColor redColor];
        }
        sqlite3_finalize(statement);
        sqlite3_close(_contactDB);
    }

}


- (IBAction)findContact:(id)sender {
    
    const char *dbpath = [_databasePath UTF8String];
    sqlite3_stmt    *statement;
    
    if (sqlite3_open(dbpath, &_contactDB) == SQLITE_OK)
    {
        NSString *querySQL = [NSString stringWithFormat:
                              @"SELECT location, address, phone, email FROM contacts WHERE name = \"%@\"",
                              _name.text];
        
        const char *query_stmt = [querySQL UTF8String];
        
        if (sqlite3_prepare_v2(_contactDB,
                               query_stmt, -1, &statement, NULL) == SQLITE_OK)
        {
            if (sqlite3_step(statement) == SQLITE_ROW)
            {
                NSString *location = [[NSString alloc]
                                        initWithUTF8String:(const char *)
                                        sqlite3_column_text(statement, 0)];
                _location.text = location;

                NSString *address = [[NSString alloc]
                                          initWithUTF8String:
                                          (const char *) sqlite3_column_text(
                                                                             statement, 1)];
                _address.text = address;
                NSString *phone = [[NSString alloc]
                                        initWithUTF8String:(const char *)
                                        sqlite3_column_text(statement, 2)];
                _phoneNumber.text = phone;
                
                NSString *email = [[NSString alloc]
                                   initWithUTF8String:(const char *)
                                   sqlite3_column_text(statement, 3)];
                _email.text = email;

                _status.text = @"Match found for the saved record";
                _status.textColor = [UIColor greenColor];

            } else {
                _status.text = @"Match not found";
                _status.textColor = [UIColor redColor];

                _address.text = @"";
                _phoneNumber.text = @"";
                _email.text = @"";
                _location.text = @"";

            }
            sqlite3_finalize(statement);
        }
        sqlite3_close(_contactDB);
    }

}


#pragma mark - Private Methods

- (NSString *)databasePath
{
    if (_databasePath == nil) {
        NSString *docsDir;
        NSArray *dirPaths;
        // Get the documents directory
        dirPaths = NSSearchPathForDirectoriesInDomains(
                                                       NSDocumentDirectory, NSUserDomainMask, YES);
        
        docsDir = dirPaths[0];
        
        // Build the path to the database file
        _databasePath = [[NSString alloc]
                         initWithString: [docsDir stringByAppendingPathComponent:
                                          @"contacts.db"]];

    }
    return _databasePath;
}

- (void)createDBIfNeeded
{
    NSFileManager *filemgr = [NSFileManager defaultManager];
    
    if ([filemgr fileExistsAtPath: self.databasePath ] == NO)
    {
        NSLog(@"\nDBPath %@\n", self.databasePath);

        const char *dbpath = [_databasePath UTF8String];
        
        if (sqlite3_open(dbpath, &_contactDB) == SQLITE_OK)
        {
            char *errMsg;
            const char *sql_stmt =
            "CREATE TABLE IF NOT EXISTS CONTACTS (ID INTEGER PRIMARY KEY AUTOINCREMENT, NAME TEXT, LOCATION TEXT,ADDRESS TEXT, PHONE TEXT, EMAIL TEXT)";
            
            if (sqlite3_exec(_contactDB, sql_stmt, NULL, NULL, &errMsg) != SQLITE_OK)
            {
                _status.text = @"Failed to create table";
                _status.textColor = [UIColor redColor];
            }
            sqlite3_close(_contactDB);
        } else {
            _status.text = @"Failed to open/create database";
            _status.textColor = [UIColor redColor];
        }
    }

}


@end
