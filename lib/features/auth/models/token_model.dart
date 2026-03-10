class TokenModel {

  final String accessToken;
  final String tokenType;

  TokenModel({
    required this.accessToken,
    required this.tokenType,
  });

  factory TokenModel.fromJson(Map<String, dynamic> json) {
    return TokenModel(
      accessToken: json["access_token"],
      tokenType: json["token_type"],
    );
  }
}