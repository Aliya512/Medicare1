module.exports = {
  testRunner: {
    args: {
      '$0': 'jest',
      config: 'e2e/jest.config.js'
    }
  },

  apps: {
    android: {
      type: 'android.apk',
      binaryPath: 'build/app/outputs/flutter-apk/app-debug.apk'
    }
  },

  devices: {
    emulator: {
      type: 'android.emulator',
      device: {
        avdName: 'Medium_Phone_API_36.1'
      }
    }
  },

  configurations: {
    android: {
      device: 'emulator',
      app: 'android'
    }
  }
};