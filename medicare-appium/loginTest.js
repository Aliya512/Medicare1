const { remote } = require("webdriverio");

async function loginTest() {

    const driver = await remote({
        hostname: "127.0.0.1",
        port: 4723,
        path: "/",
        capabilities: {
            platformName: "Android",
            "appium:automationName": "UiAutomator2",
            "appium:deviceName": "Android Emulator",
            "appium:app": "C:/Users/aliya/Downloads/Semester 5/Mobile Application Development/medicare1/build/app/outputs/flutter-apk/app-debug.apk"
        }
    });

    const emailField =
        await driver.$('//android.widget.FrameLayout[@resource-id="android:id/content"]/android.widget.FrameLayout/android.view.View/android.view.View/android.view.View/android.view.View/android.view.View/android.view.View/android.widget.EditText[1]');
    await emailField.click();
    await driver.pause(1000);
    await emailField.setValue("admin@gmail.com");
 

    const passwordField =
        await driver.$('//android.widget.FrameLayout[@resource-id="android:id/content"]/android.widget.FrameLayout/android.view.View/android.view.View/android.view.View/android.view.View/android.view.View/android.view.View/android.widget.EditText[2]');
    await passwordField.click();
    await driver.pause(1000);
    await passwordField.setValue("admin123");
 
    const loginButton =
        await driver.$('//android.widget.Button[@content-desc="LOGIN"]');

    await loginButton.click();

    console.log("Login Test Executed");

    await driver.pause(15000);

    await driver.deleteSession();
}

loginTest();
