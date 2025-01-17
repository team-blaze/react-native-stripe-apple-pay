import Foundation
import PassKit
import StripeApplePay

@objc(StripeApplePay)
class StripeApplePay: NSObject, ApplePayContextDelegate {
  var clientSecret: String? = nil

  var merchantIdentifier: String? = nil

  var applePayRequestResolver: RCTPromiseResolveBlock? = nil
  var applePayRequestRejecter: RCTPromiseRejectBlock? = nil

  var applePayRequestClientSecret: String? = nil

  var applePayCompletionCallback: STPIntentClientSecretCompletionBlock? = nil

  @objc(initialise:resolver:rejecter:)
  func initialise(params: NSDictionary, resolver resolve: @escaping RCTPromiseResolveBlock, rejecter reject: @escaping RCTPromiseRejectBlock) -> Void {
      let publishableKey = params["publishableKey"] as! String
      let merchantIdentifier = params["merchantIdentifier"] as? String

      StripeAPI.defaultPublishableKey = publishableKey

      self.merchantIdentifier = merchantIdentifier

      resolve(NSNull())
  }

  @objc(isApplePaySupported:rejecter:)
  func isApplePaySupported(resolver resolve: @escaping RCTPromiseResolveBlock,
                           rejecter reject: @escaping RCTPromiseRejectBlock) {
      let isSupported = StripeAPI.deviceSupportsApplePay()
      resolve(isSupported)
  }

  @objc(
    presentApplePay:clientSecret:resolver:rejecter:
  )
  func presentApplePay(
    params: NSDictionary,
    clientSecret: String?,
    resolve: @escaping RCTPromiseResolveBlock,
    reject: @escaping RCTPromiseRejectBlock
  ) {
    self.clientSecret = clientSecret
    self.applePayRequestResolver = resolve
    self.applePayRequestRejecter = reject

    let (error, paymentRequest) = ApplePayUtils.createPaymentRequest(merchantIdentifier: merchantIdentifier, params: params)
    guard let paymentRequest = paymentRequest else {
        resolve(error)
        return
    }

    if let applePayContext = STPApplePayContext(paymentRequest: paymentRequest, delegate: self) {
        DispatchQueue.main.async {
            applePayContext.presentApplePay(completion: nil)
        }
    } else {
        resolve(Errors.createError(ErrorType.Failed, "Payment not completed"))
    }
  }

  @objc(confirmApplePayPayment:resolver:rejecter:)
  func confirmApplePayPayment(clientSecret: String, resolver resolve: @escaping RCTPromiseResolveBlock, rejecter reject: @escaping RCTPromiseRejectBlock) {
      self.applePayRequestRejecter = reject
      self.applePayRequestResolver = resolve
      self.applePayCompletionCallback?(clientSecret, nil)
  }

  public func applePayContext(
    _ context: STPApplePayContext,
    didCreatePaymentMethod paymentMethod: StripeCore.StripeAPI.PaymentMethod,
    paymentInformation: PKPayment, completion: @escaping STPIntentClientSecretCompletionBlock
  ) {
    if let clientSecret = self.applePayRequestClientSecret {
        completion(clientSecret, nil)
    } else {
        self.applePayCompletionCallback = completion
        applePayRequestResolver?(["result": "success"])
        self.applePayRequestRejecter = nil
    }
  }

  public func applePayContext(
    _ context: STPApplePayContext, didCompleteWith status: STPApplePayContext.PaymentStatus,
    error: Error?
  ) {
    switch status {
    case .success:
        applePayRequestResolver?(["result": "success"])
        break
    case .error:
        let message = "Payment not completed"
        applePayRequestRejecter?(ErrorType.Failed, message, nil)
        break
    case .userCancellation:
        let message = "The payment has been canceled"
        applePayRequestRejecter?(ErrorType.Canceled, message, nil)
        break
    @unknown default:
        let message = "Payment not completed"
        applePayRequestRejecter?(ErrorType.Unknown, message, nil)
        break
    }
    applePayRequestRejecter = nil
  }

}
