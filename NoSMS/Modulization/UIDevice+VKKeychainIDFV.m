







#import "UIDevice+VKKeychainIDFV.h"

@implementation UIDevice (VKKeychainIDFV)

+(NSString *)VKKeychainIDFV
{
    return [[self currentDevice] VKKeychainIDFV];
}

-(NSString *)VKKeychainIDFV
{
    NSString *idfv = [self VKgetIdfvFromKeyChain];

    if (idfv && idfv.length > 0 && [idfv isKindOfClass:[NSString class]]) {
        return idfv;
    }else
    {
        NSString *idfv = [[self identifierForVendor] UUIDString];
        idfv = [idfv stringByReplacingOccurrencesOfString:@"-" withString:@""];
        [self VKsaveIdfvToKeyChain:idfv];
        return idfv;
    }
}


-(void)removeVKKeychainIDFV
{
    NSString *keychainKey = [[NSBundle mainBundle] bundleIdentifier];
    keychainKey = [keychainKey stringByAppendingString:@".VKIDFV"];
    [self VKdelete:keychainKey];
}

+(void)removeVKKeychainIDFV
{
    [[self currentDevice] removeVKKeychainIDFV];
}


-(void)VKsaveIdfvToKeyChain:(NSString *)idfv
{
    NSString *keychainKey = [[NSBundle mainBundle] bundleIdentifier];
    keychainKey = [keychainKey stringByAppendingString:@".VKIDFV"];
    [self VKsave:keychainKey data:idfv];
}

-(NSString *)VKgetIdfvFromKeyChain
{
    NSString *keychainKey = [[NSBundle mainBundle] bundleIdentifier];
    keychainKey = [keychainKey stringByAppendingString:@".VKIDFV"];
    NSString * idfv = [self load:keychainKey];
    return idfv;
}


- (NSMutableDictionary *)VKgetKeychainQuery:(NSString *)service {
    return [NSMutableDictionary dictionaryWithObjectsAndKeys:
            (__bridge_transfer id)kSecClassGenericPassword,(__bridge_transfer id)kSecClass,
            service, (__bridge_transfer id)kSecAttrService,
            service, (__bridge_transfer id)kSecAttrAccount,
            (__bridge_transfer id)kSecAttrAccessibleAfterFirstUnlock,(__bridge_transfer id)kSecAttrAccessible,
            nil];
}

- (void)VKsave:(NSString *)service data:(id)data {
    
    NSMutableDictionary *keychainQuery = [self VKgetKeychainQuery:service];
    
    SecItemDelete((__bridge_retained CFDictionaryRef)keychainQuery);
    
    [keychainQuery setObject:[NSKeyedArchiver archivedDataWithRootObject:data] forKey:(__bridge_transfer id)kSecValueData];
    
    SecItemAdd((__bridge_retained CFDictionaryRef)keychainQuery, NULL);
}

- (id)load:(NSString *)service {
    id ret = nil;
    NSMutableDictionary *keychainQuery = [self VKgetKeychainQuery:service];
    
    [keychainQuery setObject:(id)kCFBooleanTrue forKey:(__bridge_transfer id)kSecReturnData];
    [keychainQuery setObject:(__bridge_transfer id)kSecMatchLimitOne forKey:(__bridge_transfer id)kSecMatchLimit];
    CFDataRef keyData = NULL;
    if (SecItemCopyMatching((__bridge_retained CFDictionaryRef)keychainQuery, (CFTypeRef *)&keyData) == noErr) {
        @try {
            ret = [NSKeyedUnarchiver unarchiveObjectWithData:(__bridge_transfer NSData *)keyData];
        } @catch (NSException *e) {
            NSLog(@"Unarchive of %@ failed: %@", service, e);
        } @finally {
        }
    }
    return ret;
}

- (void)VKdelete:(NSString *)service {
    NSMutableDictionary *keychainQuery = [self VKgetKeychainQuery:service];
    SecItemDelete((__bridge_retained CFDictionaryRef)keychainQuery);
}
@end
