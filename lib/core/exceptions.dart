import 'dart:io';

import 'package:cart_demo/utils/strings.dart';
import 'package:dio/dio.dart';

class ApiException implements Exception {
  ApiException(this.message);

  final String message;

  // ignore: prefer_constructors_over_static_methods, type_annotate_public_apis
  static ApiException getException(err) {
    switch ((err as DioError).type) {
      // if the request was cancelled
      case DioErrorType.cancel:
        return OtherExceptions(kRequestCancelledError);

      // timeout errors
      case DioErrorType.connectTimeout:
      case DioErrorType.receiveTimeout:
      case DioErrorType.sendTimeout:
        return InternetConnectException(kTimeOutError);

      // others - handle other types of custom exceptions here
      case DioErrorType.other:
        // format exception
        if (err.error is FormatException) {
          return FormatException();
        }
        // socket exception
        if (err.error is SocketException) {
          return InternetConnectException(kInternetConnectionError);
        }
        break;
      case DioErrorType.response:
        /* cases where we have a custom error message from the APIs
        We'll have a response from the APIs [for some status codes],

        IF THERE IS A PAYLOAD,

        e.g 
        {
          "status": false,
          "message": "Incorrect credentials",
        }

        we extract the value present in the key=>[message]


        {
  "status": 400,
  "error": "InvalidRequestException",
  "message": "One or more of the request fields is invalid",
  "details": [
    {
      "field": "phone_number",
      "invalid_value": "string",
      "message": "The phone number \"string\" is not valid."
    },
        */
        if (err.response?.data != null) {
          // if ((err.response!.data as Map).containsKey('details')) {
          //   if (((err.response!.data as Map)['details'] as List).isNotEmpty) {
          //     List list = ((err.response!.data as Map)['details']);
          //     if (list.any((item) => item != {})) {
          //       return OtherExceptions(list[0]);
          //     }
          //     return OtherExceptions(list[0]['message']);
          //   } else if ((err.response!.data as Map).containsKey('message')) {
          //     return OtherExceptions(
          //         (err.response?.data as Map)['message'] ?? '');
          //   } else {
          //     return OtherExceptions((err.response!.data as Map)['message']);
          //   }
          // }
          try {
            return OtherExceptions(
              (err.response?.data as Map)['message'] ?? '',
            );
          } catch (e) {
            return OtherExceptions('');
          }
        } else {
          // IF THERE IS NO PAYLOAD, we check for respective status codes and assign dimfit error messages
          switch (err.response?.statusCode) {
            case 500:
              return InternalServerException();
            case 404:
            case 502:
              return OtherExceptions(kNotFoundError);
            case 400:
              return OtherExceptions(kBadRequestError);
            case 403:
            case 401:
              return UnAuthorizedException();
            default:
              // default exception error message
              return OtherExceptions(kDefaultError);
          }
        }
    }
    // default exception error message
    return OtherExceptions(kDefaultError);
  }
}

class OtherExceptions implements ApiException {
  OtherExceptions(this.newMessage);

  final String newMessage;

  @override
  String toString() => message;

  @override
  String get message => newMessage;
}

class FormatException implements ApiException {
  @override
  String toString() => message;

  @override
  String get message => kFormatError;
}

class InternetConnectException implements ApiException {
  InternetConnectException(this.newMessage);

  final String newMessage;

  @override
  String toString() => message;

  @override
  String get message => newMessage;
}

class InternalServerException implements ApiException {
  @override
  String toString() {
    return message;
  }

  @override
  String get message => kServerError;
}

class UnAuthorizedException implements ApiException {
  @override
  String toString() {
    return message;
  }

  @override
  String get message => kUnAuthorizedError;
}
