import 'dart:math';

import 'package:flutter/material.dart';
import 'package:ps_check/main.dart';
import 'package:ps_check/spw.dart';
import 'package:ps_check/web-b.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

class TutorialManager {
  final BuildContext context;
  List<TargetFocus> targets = [];
  late TutorialCoachMark tutorialCoachMark;
  final SharedPropWrapper sharedPropWrapper;

  TutorialManager({required this.context, required this.sharedPropWrapper});

  void startMainTutorial() async {
    targets.add(getTargetFocus(
        "Setting region",
        settingKey,
        null,
        FractionalOffset.topLeft,
        null,
        CrossAxisAlignment.start,
        MainAxisAlignment.start,
        "Select your region",
        "Base on this selection ps store will show regional site, "
            "games and price"));
    targets.add(getTargetFocus(
        "Add game",
        addKeyMain,
        null,
        FractionalOffset.topRight,
        null,
        CrossAxisAlignment.start,
        MainAxisAlignment.start,
        "Tap here to start game selection",
        null));
    WidgetsBinding.instance.addPostFrameCallback((_) =>
        showTutorial(() => sharedPropWrapper.saveTutorialFlagMain(true)));
  }

  TextStyle getTextStyleForSubText() =>
      TextStyle(color: Colors.white, fontSize: 15.0);

  void startWebTutorial() async {
    targets.add(
      TargetFocus(
        identify: "find game",
        targetPosition: TargetPosition(Size(700, 400), getPosition()),
        //keyTarget: browserKey,
        color: getRandomColorFromList(),
        enableOverlayTab: true,
        contents: [
          TargetContent(
              //align: ContentAlign.bottom,
              child: Container(
                  child: Align(
            alignment: FractionalOffset.bottomLeft,
            child: SizedBox(
              width: 230.0,
              height: 300.0,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  Text(
                    "Here in the browser find the page of the game you want to track",
                    style: getMainTextSizeForTutorial(),
                  ),
                ],
              ),
            ),
          )))
        ],
        shape: ShapeLightFocus.RRect,
        radius: 0,
      ),
    );
    targets.add(
      getTargetFocus(
          "Search",
          searchKey,
          Alignment.topRight,
          FractionalOffset.bottomRight,
          ContentAlign.top,
          CrossAxisAlignment.start,
          MainAxisAlignment.end,
          "Tap here to start searching",
          "If you don't want to search in your browser, just start typing the name of the game"),
    );
    targets.add(getTargetFocus(
        "Add game",
        addKey,
        Alignment.topRight,
        FractionalOffset.bottomRight,
        ContentAlign.top,
        CrossAxisAlignment.start,
        MainAxisAlignment.end,
        "Tap here to save game in the list",
        "If there are several game cards on the page (different console options/price), "
            "a pop-up window will appear with a selection of games"));
    targets.add(
      getTargetFocus(
          "Done",
          doneKey,
          null,
          FractionalOffset.topLeft,
          null,
          CrossAxisAlignment.start,
          MainAxisAlignment.start,
          "Tap here to get back to list of selected games",
          null),
    );
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => showTutorial(() => sharedPropWrapper.saveTutorialFlagWeb(true)));
  }

  TargetFocus getTargetFocus(
      String identifier,
      GlobalKey key,
      Alignment? skip,
      FractionalOffset textPosition,
      ContentAlign? contentAlign,
      CrossAxisAlignment columnCross,
      MainAxisAlignment columnMain,
      String headerText,
      String? subText) {
    return TargetFocus(
        identify: identifier,
        keyTarget: key,
        enableOverlayTab: true,
        alignSkip: skip,
        color: getRandomColorFromList(),
        contents: [
          TargetContent(
              align: contentAlign == null ? ContentAlign.bottom : contentAlign,
              child: Container(
                  child: Align(
                      alignment: textPosition,
                      child: SizedBox(
                        width: 230.0,
                        height: 300.0,
                        child: Column(
                            crossAxisAlignment: columnCross,
                            mainAxisAlignment: columnMain,
                            children: <Widget>[
                              SizedBox(
                                height: 20,
                              ),
                              Text(
                                headerText,
                                style: getMainTextSizeForTutorial(),
                              ),
                              subText == null
                                  ? Container()
                                  : Text(
                                      subText,
                                      style: getTextStyleForSubText(),
                                    ),
                              SizedBox(
                                height: 20,
                              ),
                            ]),
                      ))))
        ],
        radius: 0);
  }

  Color getRandomColorFromList() {
    List<Color> colors = [
      Colors.purpleAccent,
      Colors.cyan,
      Colors.green,
      Colors.purple,
      Colors.amber,
      Colors.red,
      Colors.pinkAccent,
      Colors.deepPurpleAccent
    ];

    return colors[Random().nextInt(colors.length)];
  }

  TextStyle getMainTextSizeForTutorial() {
    return TextStyle(
        fontWeight: FontWeight.bold, color: Colors.white, fontSize: 17.0);
  }

  void showTutorial(VoidCallback function) {
    tutorialCoachMark = TutorialCoachMark(
      targets: targets,
      colorShadow: Colors.pink,
      textSkip: "SKIP",
      paddingFocus: 10,
      opacityShadow: 0.9,
      onFinish: () {
        function();
        print("finish");
      },
      onClickTarget: (target) {
        print('onClickTarget: $target');
      },
      onSkip: () {
        print("skip");
        return true;
      },
      onClickOverlay: (target) {
        print('onClickOverlay: $target');
      },
    )..show(context: context);
  }

  Offset getPosition() {
    return Offset(0, 100);
  }
}
