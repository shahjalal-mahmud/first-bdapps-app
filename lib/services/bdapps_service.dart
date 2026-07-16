import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../models/bdapps_response_models.dart';
import 'api_exceptions.dart';

/// Single source of HTTP traffic against the BDApps PHP gateway.
///
/// Every method issues an `application/x-www-form-urlencoded` POST to
/// one of the four production endpoints and decodes the JSON response
/// into a typed model. The PHP backend reads from `$_POST`, so JSON
/// payloads are NOT accepted - always use [http.Client.post] with a
/// `Map<String, String>` body, which the http package encodes as
/// `application/x-www-form-urlencoded` automatically.
///
/// Endpoints:
///   * send_otp.php            -> [SendOtpResponse]
///   * verify_otp.php          -> [VerifyOtpResponse]
///   * check_subscription.php  -> [SubscriptionStatusResponse]
///   * unsubscribe.php         -> [UnsubscribeResponse]
class BdappsService {
  final http.Client _client;
  final String baseUrl;

  BdappsService({http.Client? client, String? baseUrl})
    : _client = client ?? http.Client(),
      baseUrl = baseUrl ?? AppConfig.baseUrl;

  static const Map<String, String> _formHeaders = {
    'Content-Type': 'application/x-www-form-urlencoded',
    'Accept': 'application/json',
  };

  /// Sends an OTP to the supplied Bangladesh mobile number (Robi/Airtel).
  ///
  /// POST send_otp.php
  /// body: user_mobile
  Future<SendOtpResponse> sendOtp(String mobile) async {
    final body = await _postForm(
      '/send_otp.php',
      {'user_mobile': _normaliseForSend(mobile)},
    );
    return SendOtpResponse.fromJson(body);
  }

  /// Verifies an OTP previously issued via [sendOtp].
  ///
  /// POST verify_otp.php
  /// body: Otp (capital O), referenceNo
  Future<VerifyOtpResponse> verifyOtp({
    required String otp,
    required String referenceNo,
  }) async {
    final body = await _postForm('/verify_otp.php', {
      'Otp': otp,
      'referenceNo': referenceNo,
    });
    return VerifyOtpResponse.fromJson(body);
  }

  /// Checks the current subscription status of a phone number.
  ///
  /// POST check_subscription.php
  /// body: user_mobile
  Future<SubscriptionStatusResponse> checkSubscription(String mobile) async {
    final body = await _postForm(
      '/check_subscription.php',
      {'user_mobile': _normaliseForSend(mobile)},
    );
    return SubscriptionStatusResponse.fromJson(body);
  }

  /// Cancels the subscription for a phone number.
  ///
  /// POST unsubscribe.php
  /// body: user_mobile
  Future<UnsubscribeResponse> unsubscribe(String mobile) async {
    final body = await _postForm(
      '/unsubscribe.php',
      {'user_mobile': _normaliseForSend(mobile)},
    );
    return UnsubscribeResponse.fromJson(body);
  }

  // ---------------------------------------------------------------------------
  // Internals
  // ---------------------------------------------------------------------------

  /// The PHP scripts accept `018xxxxxxxx`, `88018xxxxxxxx`, or
  /// `8818xxxxxxxx`. We always send the canonical `018xxxxxxxx` form to
  /// avoid any ambiguity at the server.
  static String _normaliseForSend(String phone) {
    final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.startsWith('880') && digits.length == 13) {
      return '0${digits.substring(3)}';
    }
    if (digits.startsWith('88') && digits.length == 12) {
      return '0${digits.substring(2)}';
    }
    return digits;
  }

  Future<Map<String, dynamic>> _postForm(
    String path,
    Map<String, String> body,
  ) async {
    final uri = Uri.parse('$baseUrl$path');
    developer.log(
      'POST $uri',
      name: 'BdappsService',
      error: {'form': body},
    );

    http.Response response;
    try {
      response = await _client
          .post(uri, headers: _formHeaders, body: body)
          .timeout(AppConfig.requestTimeout);
    } on SocketException catch (e) {
      developer.log('Network failure', name: 'BdappsService', error: e);
      throw NetworkException(e.message);
    } on TimeoutException {
      developer.log('Request timed out', name: 'BdappsService', error: uri);
      throw const ServerException('Request timed out. Please try again.');
    } on HttpException catch (e) {
      developer.log('HTTP failure', name: 'BdappsService', error: e);
      throw ServerException(e.message);
    } catch (e) {
      developer.log('Unknown client failure', name: 'BdappsService', error: e);
      throw ServerException('Unexpected error: $e');
    }

    return _parse(response, uri);
  }

  Map<String, dynamic> _parse(http.Response response, Uri uri) {
    final status = response.statusCode;
    developer.log(
      'Response ${response.statusCode} for $uri',
      name: 'BdappsService',
      error: {'body': response.body},
    );

    Map<String, dynamic>? decoded;
    if (response.body.isNotEmpty) {
      try {
        final raw = jsonDecode(response.body);
        if (raw is Map<String, dynamic>) {
          decoded = raw;
        } else {
          throw const FormatException('Top-level JSON is not an object');
        }
      } on FormatException catch (e) {
        throw UnexpectedResponseException(
          'Server returned an invalid response (${e.message})',
        );
      }
    }

    if (status >= 200 && status < 300) {
      return decoded ?? const <String, dynamic>{};
    }

    final serverMessage = decoded?['message']?.toString() ??
        decoded?['error']?.toString() ??
        'HTTP $status';

    if (status >= 400 && status < 500) {
      throw BadRequestException(
        serverMessage,
        serverMessage: serverMessage,
        statusCode: status,
      );
    }

    throw ServerException(serverMessage, statusCode: status);
  }

  void dispose() => _client.close();
}