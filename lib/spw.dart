import 'package:shared_preferences/shared_preferences.dart';

class SharedPropWrapper{
  var region;
  var prefs;
  var prefRegionName = 'region';
  var prefTutorialNameMain = 'passedTutorial';
  var prefTutorialNameWeb = 'passedTutorialWeb';
  bool? prefTutorialNameMainValue;
  bool? prefTutorialNameWebValue;
  static SharedPropWrapper regionInternal = SharedPropWrapper();

  static SharedPropWrapper instance(){
    return regionInternal;
  }

  isInitiated() async{
    if (prefs == null){
      prefs = await SharedPreferences.getInstance();
    }
  }
   readRegion() async {
     await isInitiated();
     if (region == null) {
       region = prefs.getString(prefRegionName);
       if (region != null) {
         print(region);
         return Future.value(region);
       } else {
         region = 'en-gb';
         return Future.value(region);
       }
     } else {
       print("from local " + region);
       return Future.value(region);
     }
   }

  saveRegion(String value) async {
    await isInitiated();
    print('save in db');
    prefs.setString(prefRegionName, value);
    region = value;
    print('saved $value');
  }

  saveTutorialFlagMain(var passedTutorial) async {
    await isInitiated();
    prefs.setBool(prefTutorialNameMain, passedTutorial);
    print('saved $passedTutorial');
    prefTutorialNameMainValue = passedTutorial;
  }

  readTutorialFlagMain() async {
    if (prefTutorialNameMainValue == null || prefTutorialNameMainValue!) {
      await isInitiated();
      print('read from shared prop');
      final value = prefs.getBool(prefTutorialNameMain) ?? false;
      print('read: $value');
      return value;
    } else {
      return prefTutorialNameMainValue;
    }
  }

  saveTutorialFlagWeb(var passedTutorial) async {
    await isInitiated();
    prefs.setBool(prefTutorialNameWeb, passedTutorial);
    print('saved $passedTutorial');
    prefTutorialNameWebValue = passedTutorial;
  }

  readTutorialFlagWeb() async {
    if (prefTutorialNameWebValue == null || prefTutorialNameWebValue!) {
      await isInitiated();
      print('read from shared prop');
      final value = prefs.getBool(prefTutorialNameWeb) ?? false;
      print('read: $value');
      return value;
    } else {
      return prefTutorialNameWebValue;
    }
  }
}

List<Region> getLocations() {
  return [
    Region(name: 'Please select region', abbreviation: 'null'),
    Region(name: 'Argentina', abbreviation: 'es-ar'),
    Region(name: 'Australia', abbreviation: 'en-au'),
    Region(name: 'Austria (Österreich)', abbreviation: 'de-at'),

    Region(name: 'Bahrain (English)', abbreviation: 'en-bh'),
    Region(name: 'Bahrain (Arabic)', abbreviation: 'ar-bh'),
    Region(name: 'Belgium (Français)', abbreviation: 'fr-be'),
    Region(name: 'Belgium (Nederlands)', abbreviation: 'de-at'),
    Region(name: 'Bolivia', abbreviation: 'es-bo'),
    Region(name: 'Brasil', abbreviation: 'pt-br'),
    Region(name: 'Bulgaria (English)', abbreviation: 'en-bg'),
    //Region(name: 'Bulgaria (България)', abbreviation: 'bg-bg'),

    Region(name: 'Canada', abbreviation: 'en-ca'),
    Region(name: 'Canada (French)', abbreviation: 'fr-ca'),
    Region(name: 'Chile', abbreviation: 'es-cl'),
    Region(name: 'China', abbreviation: 'zh-hans-cn'),
    Region(name: 'Colombia', abbreviation: 'es-co'),
    Region(name: 'Costa Rica', abbreviation: 'es-cr'),
    Region(name: 'Croatia (English)', abbreviation: 'en-hr'),
    //Region(name: 'Croatia (Hrvatska)', abbreviation: 'hr-hr'),
    Region(name: 'Cyprus', abbreviation: 'en-cy'),
    Region(name: 'Czech Republic (English)', abbreviation: 'en-cz'),
    //Region(name: 'Czech Republic (Ceská Republika)', abbreviation: 'cs-cz'),

    Region(name: 'Denmark (Danmark)', abbreviation: 'da-dk'),
    Region(name: 'Denmark (English)', abbreviation: 'en-dk'),

    Region(name: 'Ecuador', abbreviation: 'es-ec'),
    Region(name: 'El Salvador', abbreviation: 'es-sv'),

    Region(name: 'Finland (English)', abbreviation: 'en-fi'),
    Region(name: 'Finland (Suomi)', abbreviation: 'fi-fi'),
    Region(name: 'France', abbreviation: 'fr-fr'),

    Region(name: 'Germany (Deutschland)', abbreviation: 'de-de'),
    Region(name: 'Greece (English)', abbreviation: 'en-gr'),
    //Region(name: 'Greece (Ελλαδα)', abbreviation: 'el-gr'),
    Region(name: 'Guatemala', abbreviation: 'es-gt'),

    Region(name: 'Honduras', abbreviation: 'es-hn'),
    Region(name: 'Hong Kong (English)', abbreviation: 'en-hk'),
    Region(name: 'Hong Kong (简体中文)', abbreviation: 'zh-hans-hk'),
    Region(name: 'Hong Kong (繁體中文)', abbreviation: 'zh-hant-hk'),
    //??Region(name: '香港 (繁體中文)', abbreviation: 'cht-hk'),
    //??Region(name: '香港 (简体中文)', abbreviation: 'chs-hk'),
    Region(name: 'Hungary (English)', abbreviation: 'en-hu'),
    //Region(name: 'Hungary (Magyarország)', abbreviation: 'hu-hu'),

    Region(name: 'Iceland (English)', abbreviation: 'en-is'),
    Region(name: 'India', abbreviation: 'en-in'),
    Region(name: 'Indonesia (English)', abbreviation: 'en-id'),
    Region(name: 'Ireland', abbreviation: 'en-ie'),
    Region(name: 'Israel (English)', abbreviation: 'en-il'),
    //Region(name: 'Israel', abbreviation: 'he-il'),
    Region(name: 'Italy', abbreviation: 'it-it'),

    Region(name: 'Japan (日本)', abbreviation: 'ja-jp'),

    Region(name: 'Korea (한국어)', abbreviation: 'ko-kr'),
    Region(name: 'Kuwait (Arabic)', abbreviation: 'ar-kw'),
    Region(name: 'Kuwait (English)', abbreviation: 'en-kw'),

    Region(name: 'Lebanon (Arabic)', abbreviation: 'ar-lb'),
    Region(name: 'Lebanon (English)', abbreviation: 'en-lb'),
    Region(name: 'Luxembourg (Deutsch)', abbreviation: 'de-lu'),
    Region(name: 'Luxembourg (Français)', abbreviation: 'fr-lu'),

    Region(name: 'Malaysia (English)', abbreviation: 'en-my'),
    Region(name: 'Malta', abbreviation: 'en-mt'),
    Region(name: 'Mexico (México)', abbreviation: 'es-mx'),

    Region(name: 'Nederland', abbreviation: 'nl-nl'),
    Region(name: 'New Zealand', abbreviation: 'en-nz'),
    Region(name: 'Nicaragua', abbreviation: 'es-ni'),
    Region(name: 'Norway (English)', abbreviation: 'en-no'),
    Region(name: 'Norway (Norge)', abbreviation: 'no-no'),

    Region(name: 'Oman (Arabic)', abbreviation: 'ar-om'),
    Region(name: 'Oman (English)', abbreviation: 'en-om'),

    Region(name: 'Panama (Panamá)', abbreviation: 'es-pa'),
    Region(name: 'Paraguay', abbreviation: 'es-py'),
    Region(name: 'Peru (Perú)', abbreviation: 'es-pe'),
    //Region(name: 'Philippines (English)', abbreviation: 'en-ph'),
    Region(name: 'Poland (English)', abbreviation: 'en-pl'),
    Region(name: 'Poland (Polska)', abbreviation: 'pl-pl'),
    Region(name: 'Portugal', abbreviation: 'pt-pt'),

    Region(name: 'Qatar (Arabic)', abbreviation: 'ar-qa'),
    Region(name: 'Qatar (English)', abbreviation: 'en-qa'),

    Region(name: 'Romania (English)', abbreviation: 'en-ro'),
    //Region(name: 'Romania (România)', abbreviation: 'ro-ro'),
    Region(name: 'Russia (Россия)', abbreviation: 'ru-ru'),

    Region(name: 'Saudi Arabia (Arabic)', abbreviation: 'ar-sa'),
    Region(name: 'Saudi Arabia (English)', abbreviation: 'en-sa'),
    //Region(name: 'Serbia (Srbija)', abbreviation: 'sr-rs'),
    Region(name: 'Singapore (English)', abbreviation: 'en-sg'),
    Region(name: 'Slovenia (English)', abbreviation: 'en-si'),
    //Region(name: 'Slovenia (Slovenija)', abbreviation: 'sl-si'),
    Region(name: 'Slovakia (English)', abbreviation: 'en-sk'),
    //Region(name: 'Slovakia (Slovenská Republika)', abbreviation: 'sk-sk'),
    Region(name: 'South Africa', abbreviation: 'en-za'),
    Region(name: 'Spain (España)', abbreviation: 'es-es'),
    Region(name: 'Sweden (English)', abbreviation: 'en-se'),
    Region(name: 'Sweden (Sverige)', abbreviation: 'sv-se'),
    Region(name: 'Switzerland (Deutsch)', abbreviation: 'de-ch'),
    Region(name: 'Switzerland (Français)', abbreviation: 'fr-ch'),
    Region(name: 'Switzerland (Italiano)', abbreviation: 'it-ch'),

    Region(name: 'Taiwan (English)', abbreviation: 'en-tw'),
    Region(name: 'Taiwan (台灣繁體中文)', abbreviation: 'zh-hant-tw'),
    Region(name: 'Thailand (English)', abbreviation: 'en-th'),
    //Region(name: 'Thailand (ภาษาไทย)', abbreviation: 'th-th'),
    Region(name: 'Turkey (English)', abbreviation: 'en-tr'),
    Region(name: 'Turkey (Türkiye)', abbreviation: 'tr-tr'),

    Region(name: 'Ukraine (Російська мова)', abbreviation: 'ru-ua'),
    //Region(name: 'Ukraine (Українська мова)', abbreviation: 'uk-ua'),
    Region(name: 'United Arab Emirates (Arabic)', abbreviation: 'ar-ae'),
    Region(name: 'United Arab Emirates (English)', abbreviation: 'en-ae'),
    Region(name: 'United States', abbreviation: 'en-us'),
    Region(name: 'United Kingdom', abbreviation: 'en-gb'),
    Region(name: 'Uruguay', abbreviation: 'es-uy'),

   //???? Region(name: 'Vietnam (English)', abbreviation: 'en-vn'),
  ];
}


class Region {
  String name;
  String abbreviation;

  Region({required this.name, required this.abbreviation});
}