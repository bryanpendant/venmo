#import "Venmo.h"

@interface Venmo (Private)

@property (assign, nonatomic) BOOL internalDevelopment;

- (NSString *)baseURLPath;

- (instancetype)initWithAppId:(NSString *)appId
                       secret:(NSString *)appSecret
                         name:(NSString *)appName;

- (NSString *)URLPathWithType:(VENTransactionType)type
                       amount:(NSUInteger)amount
                         note:(NSString *)note
                    recipient:(NSString *)recipientHandle;

- (NSString *)currentDeviceIdentifier;

@end

SpecBegin(Venmo)

describe(@"Initialization", ^{

    __block Venmo *venmo;

    beforeEach(^{
        venmo = [[Venmo alloc] initWithAppId:@"foo" secret:@"bar" name:@"Foo Bar App"];
    });

    it(@"should have an internal development flag", ^{
        expect(venmo.internalDevelopment).to.beFalsy();
        venmo.internalDevelopment = YES;
        expect(venmo.internalDevelopment).to.beTruthy();
    });

    it(@"should correctly set the app id, secret, and name", ^{
        expect(venmo.appId).to.equal(@"foo");
        expect(venmo.appSecret).to.equal(@"bar");
        expect(venmo.appName).to.equal(@"Foo Bar App");
    });
});

describe(@"baseURLPath", ^{

    __block Venmo *venmo;

    beforeEach(^{
        venmo = [[Venmo alloc] initWithAppId:@"foo" secret:@"bar" name:@"Foo Bar App"];
    });

    it(@"should return correct base URL path based on internal development flag.", ^{
        expect([venmo baseURLPath]).to.equal(@"http://api.venmo.com/v1/");
        venmo.internalDevelopment = YES;
        expect([venmo baseURLPath]).to.equal(@"http://api.dev.venmo.com/v1/");
    });   
});

describe(@"startWithAppId:secret:name:", ^{

    it(@"should create a singleton instance", ^{
        BOOL started = [Venmo startWithAppId:@"foo" secret:@"bar" name:@"Foo Bar App"];
        expect(started).to.equal(YES);
        Venmo *sharedVenmo = [Venmo sharedInstance];
        expect(sharedVenmo).toNot.beNil();

        started = [Venmo startWithAppId:@"foo" secret:@"bar" name:@"Foo Bar App"];
        expect(started).to.equal(NO);
        expect([Venmo sharedInstance]).to.equal(sharedVenmo);
    });

});


describe(@"URLPathWithType:amount:note:recipient:", ^{

    __block Venmo *venmo;
    __block id mockVenmo;
    __block NSString *appId;
    __block NSString *appSecret;
    __block NSString *appName;

    beforeEach(^{
        appId = @"foo";
        appSecret = @"bar";
        appName = @"AppName";

        venmo = [[Venmo alloc] initWithAppId:appId secret:appSecret name:appName];
        mockVenmo = [OCMockObject partialMockForObject:venmo];
        [[[mockVenmo stub] andReturn:@"deviceId"] currentDeviceIdentifier];
    });

    it(@"should return the correct path for a charge", ^{
        NSString *path = [mockVenmo URLPathWithType:VENTransactionTypePay amount:100 note:@"test" recipient:@"cookie"];
        expect([path rangeOfString:@"client=ios"].location).toNot.equal(NSNotFound);
        expect([path rangeOfString:@"app_name=AppName"].location).toNot.equal(NSNotFound);
        expect([path rangeOfString:@"device_id=deviceId"].location).toNot.equal(NSNotFound);
        expect([path rangeOfString:@"amount=1.00"].location).toNot.equal(NSNotFound);
        expect([path rangeOfString:@"txn=pay"].location).toNot.equal(NSNotFound);
        expect([path rangeOfString:@"recipients=cookie"].location).toNot.equal(NSNotFound);
        expect([path rangeOfString:@"note=test"].location).toNot.equal(NSNotFound);
        NSString *versionString = [NSString stringWithFormat:@"app_version=%@", VEN_CURRENT_SDK_VERSION];
        expect([path rangeOfString:versionString].location).toNot.equal(NSNotFound);
    });

    it(@"should return the correct path for a payment", ^{
        NSString *path = [mockVenmo URLPathWithType:VENTransactionTypeCharge amount:9999 note:@"testnote" recipient:@"cookie@venmo.com"];
        expect([path rangeOfString:@"txn=charge"].location).toNot.equal(NSNotFound);
    });

});

SpecEnd