const { remote } = require("webdriverio");
async function passwordMismatchTest() {
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
    const signupButton = await driver .$ ('//android.widget.Button[@content-desc="Don’t have an account? Create one"]');
    await signupButton.click();
    await driver.pause(1000);

    const emailField =
        await driver.$('//android.widget.FrameLayout[@resource-id="android:id/content"]/android.widget.FrameLayout/android.view.View/android.view.View/android.view.View/android.view.View/android.view.View/android.view.View/android.view.View/android.widget.EditText[1]');
    await emailField.click();
    await driver.pause(1000);
    await emailField.setValue("user@gmail.com");
 
    const userNameField =
        await driver.$('//android.widget.FrameLayout[@resource-id="android:id/content"]/android.widget.FrameLayout/android.view.View/android.view.View/android.view.View/android.view.View/android.view.View/android.view.View/android.view.View/android.widget.EditText[2]');
    await userNameField.click();
    await driver.pause(1000);
    await userNameField.setValue("Another User");

    const passwordField =
        await driver.$('//android.widget.FrameLayout[@resource-id="android:id/content"]/android.widget.FrameLayout/android.view.View/android.view.View/android.view.View/android.view.View/android.view.View/android.view.View/android.view.View/android.widget.EditText[3]');
    await passwordField.click();
    await driver.pause(1000);
    await passwordField.setValue("Password123");

    const confirmPasswordField =
        await driver.$('//android.widget.FrameLayout[@resource-id="android:id/content"]/android.widget.FrameLayout/android.view.View/android.view.View/android.view.View/android.view.View/android.view.View/android.view.View/android.view.View/android.widget.EditText[4]');
    await confirmPasswordField.click();
    await driver.pause(1000);
    await confirmPasswordField.setValue("NewPassword123");
 
    const registerButton =
        await driver.$('//android.widget.Button[@content-desc="REGISTER"]');
    await registerButton.click();

    console.log("Password Mismatch Test Executed");
    await driver.pause(15000);
    await driver.deleteSession();
}
passwordMismatchTest();