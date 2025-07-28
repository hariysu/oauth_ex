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

                    // Sadece dış tırnakları kırp
                    if (cleaned.startsWith('"') && cleaned.endsWith('"')) {
                      cleaned = cleaned.substring(1, cleaned.length - 1);
                    }

                    // Debug için ham veriyi yazdır
                    debugPrint('Cleaned JSON: $cleaned');

                    // Dış JSON'u ayrıştır
                    final outerJson = jsonDecode(cleaned);

                    // İçteki string olarak gelen JSON'u da ayrıştır
                    final innerJsonString = outerJson['ExternalCallbackResult'];
                    final innerJson = jsonDecode(innerJsonString);
                    final userJson = innerJson['user'] as Map<String, dynamic>;

                    final kullanici = MobilKullaniciOrganizasyonV2.fromJson(
                      userJson,
                    );

                    debugPrint(
                      'Kullanıcı adı: ${kullanici.adi} ${kullanici.soyadi}',
                    );
                    debugPrint(
                      'İdare sayısı: ${kullanici.idareBilgileri.length}',
                    );
                    debugPrint(
                      'İlk idare: ${kullanici.idareBilgileri[0].idareninAdi}',
                    );

                    Navigator.pop(context, kullanici);
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
              'https://giris.build.turkiye.gov.tr/OAuth2AuthorizationServer/AuthorizationController?client_id=f552cc50-34b5-4da6-8ce4-a541a9fdc42e&redirect_uri=https%3a%2f%2ftsrcekapws.kik.gov.tr%2fKikServisleri%2fGuvenliMobilCihazBilgiServisi.svc%2fExternalCallback&response_type=code&scope=Kimlik-Dogrula+Ad-Soyad&state=NjNiMGY0ZWZmMGM0NGEwOWI2YWRlZGQ4OWEyZjYzM2M%3d&code_challenge=zlcK2UzHgFLSFnAwFB9v1vWs8JMaBg7kCpsOZLwBmc7dhcohyLbdbJk3JsLs&+=S256',
            ),
          );
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
      adi: json['Adi'] as String? ?? '',
      soyadi: json['Soyadi'] as String? ?? '',
      istekliBilgleri:
          (json['IstekliBilgleri'] as List<dynamic>?)
              ?.map((e) => IstekliBilgleri.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      idareBilgileri:
          (json['IdareBilgileri'] as List<dynamic>?)
              ?.map((e) => IdareBilgileri.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      sonuc:
          json['Sonuc'] != null
              ? BoolResultVS2.fromJson(json['Sonuc'] as Map<String, dynamic>)
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
      organizasyonID: json['OrganizasyonID'] as String? ?? '',
      organizasyonIDMD5: json['OrganizasyonIDMD5'] as String? ?? '',
      organizasyonAdi: json['OrganizasyonAdi'] as String? ?? '',
      unvan: json['Unvan'] as String? ?? '',
      tcKimlikNo: json['TcKimlikNo'] as String? ?? '',
      vergiNo: json['VergiNo'] as String? ?? '',
      adres: json['Adres'] as String? ?? '',
      telefon: json['Telefon'] as String? ?? '',
      ePosta: json['EPosta'] as String? ?? '',
      odaSicilNo: json['OdaSicilNo'] as String? ?? '',
      sirketTuru: json['SirketTuru'] as String? ?? '',
      ticariOdaAdi: json['TicariOdaAdi'] as String? ?? '',
      meslekOdasiAdi: json['MeslekOdasiAdi'] as String? ?? '',
      gercekTuzelKurum: json['GercekTuzelKurum'] as String? ?? '',
      ilMerkezi: json['IlMerkezi'] as String? ?? '',
      yabanciKimlikNo: json['YabanciKimlikNo'] as bool? ?? false,
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
      organizasyonID: json['OrganizasyonID'] as String? ?? '',
      idareninAdi: json['IdareninAdi'] as String? ?? '',
      ustIdareninAdi: json['UstIdareninAdi'] as String? ?? '',
      enUstIdareninAdi: json['EnUstIdareninAdi'] as String? ?? '',
      detsisNumarasi: json['DETSİSNumarasi'] as String? ?? '',
      vergiNo: json['VergiNo'] as String? ?? '',
      ePostaAdresi: json['EPostaAdresi'] as String? ?? '',
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
      sonuc: json['Sonuc'] as bool? ?? false,
      mesaj: json['Mesaj'] as String? ?? '',
      uniqueName: json['UniqueName'] as String?,
      resultCode: json['ResultCode'] as int? ?? -1,
    );
  }
}
