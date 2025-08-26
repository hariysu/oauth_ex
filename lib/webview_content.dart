import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class WebViewContent extends StatefulWidget {
  final VoidCallback onSuccess;
  const WebViewContent({super.key, required this.onSuccess});

  @override
  State<WebViewContent> createState() => _WebViewContentState();
}

class _WebViewContentState extends State<WebViewContent> {
  late final WebViewController controller;
  bool _hasError = false;
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();
    controller =
        WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..setNavigationDelegate(
            NavigationDelegate(
              onProgress: (int progress) {
                setState(() {
                  _progress = progress / 100.0;
                });
              },
              onPageStarted: (String url) {},
              onPageFinished: (String url) async {
                if (url.contains("/ExternalCallback")) {
                  try {
                    final rawResult = await controller
                        .runJavaScriptReturningResult(
                          "document.body.innerText",
                        );

                    String cleaned = rawResult.toString();

                    // Debug için ham veriyi yazdır
                    debugPrint('Cleaned JSON: $cleaned');

                    // JSON'u ayrıştır
                    final jsonData = jsonDecode(cleaned);

                    // Token ve mobilKullaniciOrganizasyonV2 içeren format
                    if (jsonData.containsKey('mobilKullaniciOrganizasyonV2')) {
                      final authResponse = AuthResponse.fromJson(jsonData);
                      debugPrint('Token: ${authResponse.token}');

                      _handleUserData(
                        authResponse.mobilKullaniciOrganizasyonV2,
                      );
                    } else {
                      debugPrint('Bilinmeyen JSON formatı');
                    }
                  } catch (e) {
                    debugPrint("JSON ayrıştırma hatası: $e");
                    // Hata durumunda ham veriyi de yazdır
                    final rawResult = await controller
                        .runJavaScriptReturningResult(
                          "document.body.innerText",
                        );
                    debugPrint("Ham veri: $rawResult");
                  }
                }
                setState(() {
                  _progress = 1.0;
                });
              },
              onHttpError: (HttpResponseError error) {
                setState(() {
                  _hasError = true;
                });
              },
              onWebResourceError: (WebResourceError error) {
                setState(() {
                  _hasError = true;
                });
              },
              onNavigationRequest: (NavigationRequest request) {
                // Success case
                if (request.url.contains(
                  'EkapAccount/ExternalCallBack?code=',
                )) {
                  //print(request.url);
                  widget.onSuccess();
                  return NavigationDecision.prevent;
                }
                // Error case
                else if (request.url.contains(
                      'EkapAccount/ExternalCallBack?error=',
                    ) ||
                    request.url.contains(
                      'EkapAccount/ExternalCallBack?error_description=',
                    )) {
                  setState(() {
                    _hasError = true;
                  });
                  return NavigationDecision.prevent;
                }
                return NavigationDecision.navigate;
              },
            ),
          )
          ..loadRequest(
            Uri.parse(
              'https://rcekapapi.kik.gov.tr/KikMobilServicesApi/api/Auth/RedirectEdevletLogin',
            ),
          );
  }

  void _handleUserData(MobilKullaniciOrganizasyonV2 kullanici) {
    debugPrint('Kullanıcı adı: ${kullanici.adi} ${kullanici.soyadi}');
    debugPrint('İdare sayısı: ${kullanici.idareBilgileri.length}');

    // İlk idareninAdi'yi yazdır
    if (kullanici.idareBilgileri.isNotEmpty) {
      debugPrint('İlk idare: ${kullanici.idareBilgileri[0].idareninAdi}');
    } else {
      debugPrint('İdare bilgisi bulunamadı');
    }

    //Navigator.pop(context, kullanici);
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, color: Colors.red, size: 64),
              SizedBox(height: 24),
              Text(
                'Lütfen daha sonra tekrar deneyin',
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.black54,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    return Stack(
      children: [
        WebViewWidget(controller: controller),
        if (_progress < 1.0)
          Positioned.fill(
            child: Center(
              child: CircularProgressIndicator(/* value: _progress */),
            ),
          ),
      ],
    );
  }
}

class AuthResponse {
  final String token;
  final String refreshToken;
  final String tokenExpires;
  final String refreshTokenExpires;
  final MobilKullaniciOrganizasyonV2 mobilKullaniciOrganizasyonV2;
  final int errorCode;
  final String? errorMessage;

  AuthResponse({
    required this.token,
    required this.refreshToken,
    required this.tokenExpires,
    required this.refreshTokenExpires,
    required this.mobilKullaniciOrganizasyonV2,
    required this.errorCode,
    this.errorMessage,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      token: json['token'] as String? ?? '',
      refreshToken: json['refreshToken'] as String? ?? '',
      tokenExpires: json['tokenExpires'] as String? ?? '',
      refreshTokenExpires: json['refreshTokenExpires'] as String? ?? '',
      mobilKullaniciOrganizasyonV2: MobilKullaniciOrganizasyonV2.fromJson(
        json['mobilKullaniciOrganizasyonV2'] as Map<String, dynamic>,
      ),
      errorCode: json['errorCode'] as int? ?? -1,
      errorMessage: json['errorMessage'] as String?,
    );
  }
}

class MobilKullaniciOrganizasyonV2 {
  final String adi;
  final String soyadi;
  final List<IstekliBilgleri> istekliBilgleri;
  final List<IdareBilgileri> idareBilgileri;
  final BoolResultVS2 sonuc;

  MobilKullaniciOrganizasyonV2({
    required this.adi,
    required this.soyadi,
    required this.istekliBilgleri,
    required this.idareBilgileri,
    required this.sonuc,
  });

  factory MobilKullaniciOrganizasyonV2.fromJson(Map<String, dynamic> json) {
    return MobilKullaniciOrganizasyonV2(
      adi: json['adi'] as String? ?? '',
      soyadi: json['soyadi'] as String? ?? '',
      istekliBilgleri:
          (json['istekliBilgleri'] as List<dynamic>?)
              ?.map((e) => IstekliBilgleri.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      idareBilgileri:
          (json['idareBilgileri'] as List<dynamic>?)
              ?.map((e) => IdareBilgileri.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      sonuc:
          json['sonuc'] != null
              ? BoolResultVS2.fromJson(json['sonuc'] as Map<String, dynamic>)
              : BoolResultVS2(
                sonuc: false,
                mesaj: 'Bilinmeyen hata',
                uniqueName: null,
                resultCode: -1,
              ),
    );
  }
}

class IstekliBilgleri {
  final String organizasyonID;
  final String organizasyonIDMD5;
  final String organizasyonAdi;
  final String unvan;
  final String tcKimlikNo;
  final String vergiNo;
  final String adres;
  final String telefon;
  final String ePosta;
  final String odaSicilNo;
  final String sirketTuru;
  final String ticariOdaAdi;
  final String meslekOdasiAdi;
  final String gercekTuzelKurum;
  final String ilMerkezi;
  final bool yabanciKimlikNo;

  IstekliBilgleri({
    required this.organizasyonID,
    required this.organizasyonIDMD5,
    required this.organizasyonAdi,
    required this.unvan,
    required this.tcKimlikNo,
    required this.vergiNo,
    required this.adres,
    required this.telefon,
    required this.ePosta,
    required this.odaSicilNo,
    required this.sirketTuru,
    required this.ticariOdaAdi,
    required this.meslekOdasiAdi,
    required this.gercekTuzelKurum,
    required this.ilMerkezi,
    required this.yabanciKimlikNo,
  });

  factory IstekliBilgleri.fromJson(Map<String, dynamic> json) {
    return IstekliBilgleri(
      organizasyonID: json['organizasyonID'] as String? ?? '',
      organizasyonIDMD5: json['organizasyonIDMD5'] as String? ?? '',
      organizasyonAdi: json['organizasyonAdi'] as String? ?? '',
      unvan: json['unvan'] as String? ?? '',
      tcKimlikNo: json['tcKimlikNo'] as String? ?? '',
      vergiNo: json['vergiNo'] as String? ?? '',
      adres: json['adres'] as String? ?? '',
      telefon: json['telefon'] as String? ?? '',
      ePosta: json['ePosta'] as String? ?? '',
      odaSicilNo: json['odaSicilNo'] as String? ?? '',
      sirketTuru: json['sirketTuru'] as String? ?? '',
      ticariOdaAdi: json['ticariOdaAdi'] as String? ?? '',
      meslekOdasiAdi: json['meslekOdasiAdi'] as String? ?? '',
      gercekTuzelKurum: json['gercekTuzelKurum'] as String? ?? '',
      ilMerkezi: json['ilMerkezi'] as String? ?? '',
      yabanciKimlikNo: json['yabanciKimlikNo'] as bool? ?? false,
    );
  }
}

class IdareBilgileri {
  final String organizasyonID;
  final String idareninAdi;
  final String ustIdareninAdi;
  final String enUstIdareninAdi;
  final String detsisNumarasi;
  final String vergiNo;
  final String ePostaAdresi;

  IdareBilgileri({
    required this.organizasyonID,
    required this.idareninAdi,
    required this.ustIdareninAdi,
    required this.enUstIdareninAdi,
    required this.detsisNumarasi,
    required this.vergiNo,
    required this.ePostaAdresi,
  });

  factory IdareBilgileri.fromJson(Map<String, dynamic> json) {
    return IdareBilgileri(
      organizasyonID: json['organizasyonID'] as String? ?? '',
      idareninAdi: json['idareninAdi'] as String? ?? '',
      ustIdareninAdi: json['ustIdareninAdi'] as String? ?? '',
      enUstIdareninAdi: json['enUstIdareninAdi'] as String? ?? '',
      detsisNumarasi: json['detsİsNumarasi'] as String? ?? '',
      vergiNo: json['vergiNo'] as String? ?? '',
      ePostaAdresi: json['ePostaAdresi'] as String? ?? '',
    );
  }
}

class BoolResultVS2 {
  final bool sonuc;
  final String mesaj;
  final String? uniqueName;
  final int resultCode;

  BoolResultVS2({
    required this.sonuc,
    required this.mesaj,
    this.uniqueName,
    required this.resultCode,
  });

  factory BoolResultVS2.fromJson(Map<String, dynamic> json) {
    return BoolResultVS2(
      sonuc: json['sonuc'] as bool? ?? false,
      mesaj: json['mesaj'] as String? ?? '',
      uniqueName: json['uniqueName'] as String?,
      resultCode: json['resultCode'] as int? ?? -1,
    );
  }
}
