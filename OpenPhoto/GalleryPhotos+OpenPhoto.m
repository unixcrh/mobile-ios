//
//  PhotoModel+OpenPhoto.m
//  OpenPhoto
//
//  Created by Patrick Santana on 12/03/12.
//  Copyright 2012 OpenPhoto
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
// 
//  http://www.apache.org/licenses/LICENSE-2.0
// 
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//


#import "GalleryPhotos+OpenPhoto.h"

@implementation GalleryPhotos (OpenPhoto)

+ (GalleryPhotos *) galleryPhotoWithOpenPhotoInfo:(NSDictionary *) openphotoInfo 
                 inManagedObjectContext:(NSManagedObjectContext *) context
{
    GalleryPhotos *photo = nil;
        
    if ([openphotoInfo objectForKey:@"id"] == nil){
        return photo;
    }
    
    // bring by id
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"GalleryPhotos"];
    request.predicate= [NSPredicate predicateWithFormat:@"identification==%@",[NSString stringWithFormat:@"%@",[openphotoInfo objectForKey:@"id"]]];   
    
    NSError *error = nil;
    NSArray *matches = [context executeFetchRequest:request error:&error];
    
    if (error){
        NSLog(@"Error getting a photo on managed object context = %@",[error localizedDescription]);
    }
    
    // Get title of the image
    NSString *title = [openphotoInfo objectForKey:@"title"];
    if ([title class] == [NSNull class])
        title = @"";
    
    // small url and url
    NSString *urlSmall  = [NSString stringWithFormat:@"%@", [openphotoInfo objectForKey:@"path200x200"]];
    NSString *url       = [NSString stringWithFormat:@"%@", [openphotoInfo objectForKey:@"path640x960"]];
    NSString *pageUrl   = [NSString stringWithFormat:@"%@", [openphotoInfo objectForKey:@"url"]];
    
    // matches should never be null and also never more than 1
    if (!matches || [matches count] > 1){
        NSLog(@"ATTENTION: Incorrect return data from the core data %@", matches);
    }else if ([matches count] == 0){
        // it is not inserted, so we create a new one
        photo = [NSEntityDescription insertNewObjectForEntityForName:@"GalleryPhotos" inManagedObjectContext:context];
        
        // set all details
        float width = [[openphotoInfo objectForKey:@"width"] floatValue];
        float height = [[openphotoInfo objectForKey:@"height"] floatValue];
        
        // calculate the real size of the image. It will keep the aspect ratio.
        float realWidth = 0;
        float realHeight = 0;
        
        if(width/height >= 1) { 
            // portrait or square
            realWidth = 640;
            realHeight = height/width*640;
        } else { 
            // landscape
            realHeight = 960;
            realWidth = width/height*960;
        }
        
        photo.width          = [NSNumber numberWithFloat:realWidth];
        photo.height         = [NSNumber numberWithFloat:realHeight];
        photo.urlSmall       = urlSmall;
        photo.url            = url;
        photo.pageUrl        = pageUrl;
        photo.identification = [NSString stringWithFormat:@"%@",[openphotoInfo objectForKey:@"id"]];
          
        // get the date since 1970
        double d            = [[openphotoInfo objectForKey:@"dateTaken"] doubleValue];
        NSTimeInterval date =  d;
        photo.date          = [NSDate dateWithTimeIntervalSince1970:date];
        
        // needs to save
        if (![context save:&error]) {
            NSLog(@"Couldn't save Photo inside core data: %@", [error localizedDescription]);
        }
    }else{
        photo = [matches lastObject];
        
        if (![photo.urlSmall isEqualToString:urlSmall] || ![photo.url isEqualToString:url] || ![photo.title isEqualToString:title] || ![photo.pageUrl isEqualToString:pageUrl]  ){  
#ifdef DEVELOPMENT_ENABLED
            NSLog(@" ==============  Object model photo was changed, update fields on database");
#endif
            photo.urlSmall = urlSmall;
            photo.url = url;
            photo.pageUrl = pageUrl;
            photo.title = title;
            
            if (![context save:&error]) {
                NSLog(@"Couldn't update Photo inside core data: %@", [error localizedDescription]);
            }           
        }
    }
    
    return photo;   
}

+ (NSArray *) getGalleryPhotosInManagedObjectContext:(NSManagedObjectContext *)context
{
    // bring by id
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"GalleryPhotos"];
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"date" ascending:NO];
    request.sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
    
    NSError *error = nil;
    NSArray *matches = [context executeFetchRequest:request error:&error];
    
    if (error){
        NSLog(@"Error to get all photos on managed object context = %@",[error localizedDescription]);
    }
    
    NSMutableArray *result = [[NSMutableArray alloc] init];
    for (GalleryPhotos *model in matches) {
        [result addObject:[self toPhoto:model]];
    }
    
    // return photos on core data
    return [result autorelease]; 
}

+ (void) deleteAllGalleryPhotosInManagedObjectContext:(NSManagedObjectContext *)context
{
    NSFetchRequest *allPhotos = [[NSFetchRequest alloc] init];
    [allPhotos setEntity:[NSEntityDescription entityForName:@"GalleryPhotos" inManagedObjectContext:context]];
    [allPhotos setIncludesPropertyValues:NO]; //only fetch the managedObjectID
    
    NSError *error = nil;
    NSArray *photos = [context executeFetchRequest:allPhotos error:&error];
    if (error){
        NSLog(@"Error getting photos to delete all from managed object context = %@",[error localizedDescription]);
    }
    
    // now we can release the object
    [allPhotos release];
    
    for (NSManagedObject *photo in photos) {
        [context deleteObject:photo];
    }
    NSError *saveError = nil;
    if (![context save:&saveError]){
        NSLog(@"Error delete all photos from managed object context = %@",[error localizedDescription]);
    }   
}

+ (NSArray *) getGalleryPhotosFromOpenPhotoService:(NSArray *) openPhotoResult 
                     inManagedObjectContext:(NSManagedObjectContext *) context{
    
    // it will contain a list of Photo object
    NSMutableArray *photos = [[NSMutableArray alloc] init];
    
    // result can be null
    if ([openPhotoResult class] != [NSNull class]) {
        // Loop through each entry in the dictionary and create an array of Photo
        
        for (NSDictionary *photoRaw in openPhotoResult){
            GalleryPhotos *model = [self galleryPhotoWithOpenPhotoInfo:photoRaw inManagedObjectContext:context];
            if (model){
                [photos addObject: [self toPhoto:model]];
            }
        }
    }
    
    // return a auto release object
    return [photos autorelease];   
}

+ (Photo *) toPhoto:(GalleryPhotos *) model{
    return [[[Photo alloc]
             initWithURL:model.url
             smallURL:model.urlSmall
             size:CGSizeMake([model.width floatValue], [model.height floatValue]) 
             caption:model.title page:model.pageUrl] autorelease];
}

@end
