#import "FileManagerViewController.h"
#import "Cells/FileCell.h"
#import "Cells/FolderCell.h"

@interface FileManagerViewController ()

@property (strong, nonatomic) NSString *path;
@property (strong, nonatomic) NSString *selectedPath;
@property (strong, nonatomic) NSArray  *directoryContent;

@end

@implementation FileManagerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (!self.path) {
        self.path = @"/Users/vladislavmolcanov/Documents/Programming/Objective_C/iOS/UITableViewNavigationTest/applicationDirectory";
    }
        
    NSError *error = nil;
    self.directoryContent = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:self.path error:&error];
    
    if (error) {
        NSLog(@"Error: %@", [error localizedDescription]);
    }
    
    [self hideHiddenFiles];
    [self sortFolderFirst];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)setPath:(NSString *)path {
    self->_path = path;
    
    NSError *error = nil;
    self.directoryContent = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:self.path error:&error];
    
    if (error) {
        NSLog(@"Error: %@", [error localizedDescription]);
    }
    
    [self.tableView reloadData];
}


#pragma mark - Actions


- (IBAction)actionAddFolder:(UIBarButtonItem *)sender {
    __block NSString *directoryName = nil;
    
    UIAlertController *ac = [UIAlertController alertControllerWithTitle:@"Создать директорию"
                                                                message:@"Введите имя новой директории"
                                                         preferredStyle:UIAlertControllerStyleAlert];
    
    [ac addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = @"Название";
        textField.clearButtonMode = UITextFieldViewModeWhileEditing;
    }];
    
    // Кнопка <Создать>
    [ac addAction:[UIAlertAction actionWithTitle:@"Создать"
                                           style:UIAlertActionStyleDefault
                                         handler:^(UIAlertAction * _Nonnull action) {
                                             directoryName = [ac.textFields[0] text];
                                             [self createDirectoryWithName:directoryName atPath:self.path];
                                         }]];
    
    // Кнопка <Отмена>
    [ac addAction:[UIAlertAction actionWithTitle:@"Отмена"
                                           style:UIAlertActionStyleCancel
                                         handler:nil]];
    
    [self presentViewController:ac animated:YES completion:nil];
}


#pragma mark - UITableViewDataSource


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.directoryContent count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *folderCellIdentifire = @"FolderCell";
    static NSString *fileCellIdentifire = @"FileCell";
    
    NSString *name = [self.directoryContent objectAtIndex:indexPath.row];
    NSString *path = [self.path stringByAppendingPathComponent:name];
    
    if ([self isDirectoryAtIndexPath:indexPath]) {
        FolderCell *cell = [self.tableView dequeueReusableCellWithIdentifier:folderCellIdentifire];
        cell.folderNameLabel.text = name;
        
        NSArray *content = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:nil];
        cell.countOfItemsLabel.text = [NSString stringWithFormat:@"%ld items", [content count]];
        
        return cell;
    } else {
        FileCell *cell = [self.tableView dequeueReusableCellWithIdentifier:fileCellIdentifire];
        cell.fileNameLabel.text = name;
        
        unsigned long long fileSize = [[[NSFileManager defaultManager] attributesOfItemAtPath:path error:nil] fileSize];
        cell.fileSizeLabel.text = [self fileSizeFromValue:fileSize];
        
        return cell;
    }
        
    return nil;
}


- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return [self isDirectoryAtIndexPath:indexPath];
}


- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [self removeDirectoryWithName:[self.directoryContent objectAtIndex:indexPath.row] atPath:self.path];
        
        NSMutableArray *tempArray = [NSMutableArray arrayWithArray:self.directoryContent];
        [tempArray removeObjectAtIndex:indexPath.row];
        
        self.directoryContent = tempArray;
        
        [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationLeft];
    }
}


#pragma mark - UITableViewDelegate


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    const CGFloat CUSTOM_CELL_HEIGHT = 80.0f;
    return CUSTOM_CELL_HEIGHT;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if ([self isDirectoryAtIndexPath:indexPath]) {
        NSString *name = [self.directoryContent objectAtIndex:indexPath.row];
        NSString *path = [self.path stringByAppendingPathComponent:name];
        
        self.selectedPath = path;
        
        [self performSegueWithIdentifier:@"navigateDeep" sender:nil];
    }
}


#pragma mark - Segue


- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    FileManagerViewController *vc = segue.destinationViewController;
    vc.path = self.selectedPath;
}


#pragma mark - Private methods


- (NSString *)fileSizeFromValue:(unsigned long long)value {
    NSArray *dimension = @[@"B", @"KB", @"MB", @"GB", @"TB"];
    NSInteger index = 0;
    
    while (value > 1024 && index < [dimension count]) {
        value /= 1024;
        index++;
    }
    
    return [NSString stringWithFormat:@"%lld %@", value, [dimension objectAtIndex:index]];
}


- (BOOL)isDirectoryAtIndexPath:(NSIndexPath *)indexPath {
    NSString *name = [self.directoryContent objectAtIndex:indexPath.row];
    NSString *path = [self.path stringByAppendingPathComponent:name];
    
    BOOL isDirectory;
    [[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDirectory];
    
    return isDirectory;
}


- (void)hideHiddenFiles {
    NSIndexSet *indexes = [self.directoryContent indexesOfObjectsPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
        NSString *path = [self.path stringByAppendingPathComponent:obj];
        
        return ![[[NSFileManager defaultManager] attributesOfItemAtPath:path error:nil] fileExtensionHidden];
    }];
    
    self.directoryContent = [self.directoryContent objectsAtIndexes:indexes];
}


- (void)sortFolderFirst {
    NSMutableArray *folders = [NSMutableArray array];
    NSMutableArray *files = [NSMutableArray array];
    
    for (NSInteger i = 0; i < [self.directoryContent count]; i++) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:i inSection:1];
        
        if ([self isDirectoryAtIndexPath:indexPath]) {
            [folders addObject:[self.directoryContent objectAtIndex:i]];
        } else {
            [files addObject:[self.directoryContent objectAtIndex:i]];
        }
    }
    
    [folders sortUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
    [files sortUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
    
    self.directoryContent = [folders arrayByAddingObjectsFromArray:files];
}


- (void)createDirectoryWithName:(NSString *)directoryName atPath:(NSString *)path {
    NSString *fullPath = [path stringByAppendingPathComponent:directoryName];
    
    [[NSFileManager defaultManager] createDirectoryAtPath:fullPath
                              withIntermediateDirectories:NO
                                               attributes:nil
                                                    error:nil];
    
    self.directoryContent = [self.directoryContent arrayByAddingObject:directoryName];
    [self sortFolderFirst];
    [self.tableView reloadData];
}


- (void)removeDirectoryWithName:(NSString *)directoryName atPath:(NSString *)path {
    NSString *fullPath = [path stringByAppendingPathComponent:directoryName];
    
    [[NSFileManager defaultManager] removeItemAtPath:fullPath error:nil];
}

@end
