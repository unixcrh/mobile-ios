//
//  AuthenticationHelper.h
//  OpenPhoto
//
//  Created by Patrick Santana on 07/09/11.
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

#import "WebService.h"
#import "GalleryPhotos+OpenPhoto.h"
#import "TimelinePhotos+OpenPhoto.h"
#import "SyncedPhotos+OpenPhoto.h"
#import "OpenPhotoServiceFactory.h"

@interface AuthenticationHelper : NSObject{
    WebService* webService;
}
@property (nonatomic, retain) WebService *webService;

- (BOOL) isValid;
- (void) invalidateAuthentication;
- (void) startOAuthProcedure:(NSURL*) url;

@end
