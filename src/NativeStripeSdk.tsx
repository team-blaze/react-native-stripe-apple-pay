import { NativeModules, Platform } from 'react-native';

import type { ApplePay, InitialiseParams } from './types';
import type { ApplePayResult } from './types/ApplePay';

type NativeStripeSdkType = {
  initialise(params: InitialiseParams): Promise<void>;
  isApplePaySupported(): Promise<boolean>;
  presentApplePay(
    params: ApplePay.PresentParams,
    clientSecret?: string
  ): Promise<ApplePayResult>;
  confirmApplePayPayment(clientSecret: string): Promise<void>;
};

const LINKING_ERROR =
  `The package 'stripe-react-native-apple-pay' doesn't seem to be linked. Make sure: \n\n` +
  Platform.select({ ios: "- You have run 'pod install'\n", default: '' }) +
  '- You rebuilt the app after installing the package\n' +
  '- You are not using Expo Go\n';

const StripeApplePay = NativeModules.StripeApplePay
  ? NativeModules.StripeApplePay
  : new Proxy(
      {},
      {
        get() {
          throw new Error(LINKING_ERROR);
        },
      }
    );

export default StripeApplePay as NativeStripeSdkType;
