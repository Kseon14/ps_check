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
    targets.add(
      TargetFocus(
        identify: "Setting region",
        keyTarget: settingKey,
        color: Colors.red,
        enableOverlayTab: true,
        contents: [
          TargetContent(
              //align: ContentAlign.top,
              child: Container(
                  child: Align(
            alignment: FractionalOffset.topLeft,
            child: SizedBox(
              width: 230.0,
              height: 300.0,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  Text(
                    "Select your region",
                    style: getMainTextSizeForTutorial(),
                  ),
                  Text(
                    "Base on this selection ps store will show regional site, "
                    "games and price",
                    style: getTextStyleForSubText(),
                  ),
                ],
              ),
            ),
          )))
        ],
        //shape: ShapeLightFocus.RRect,
        radius: 5,
      ),
    );
    targets.add(TargetFocus(
        identify: "Add game",
        keyTarget: addKeyMain,
        enableOverlayTab: true,
        color: Colors.amber,
        contents: [
          TargetContent(
            //align: ContentAlign.bottom,
            child: Container(
                child: Align(
                    alignment: FractionalOffset.topRight,
                    child: SizedBox(
                      width: 230.0,
                      height: 300.0,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: <Widget>[
                          Text("Tap here to start game selection",
                              style: getMainTextSizeForTutorial()),
                        ],
                      ),
                    ))),
          ),
        ]));
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
        color: Colors.purple,
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
      TargetFocus(
        identify: "Add game",
        keyTarget: addKey,
        enableOverlayTab: true,
        alignSkip: Alignment.topRight,
        color: Colors.green,
        contents: [
          TargetContent(
              align: ContentAlign.top,
              child: Container(
                  child: Align(
                      alignment: FractionalOffset.bottomRight,
                      child: SizedBox(
                        width: 230.0,
                        height: 300.0,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: <Widget>[
                            Text(
                              "Tap here to save game in the list ",
                              style: getMainTextSizeForTutorial(),
                              // )
                            ),
                            Text(
                              "If there are several game cards on the page (different console options/price), "
                              "a pop-up window will appear with a selection of games",
                              style: getTextStyleForSubText(),
                            ),
                          ],
                        ),
                      ))))
        ],
      ),
    );
    targets.add(
      TargetFocus(
          identify: "Done",
          keyTarget: doneKey,
          //alignSkip: Alignment.bottomRight,
          enableOverlayTab: true,
          color: Colors.cyan,
          contents: [
            TargetContent(
                child: Container(
                    child: Align(
                        alignment: FractionalOffset.topLeft,
                        child: SizedBox(
                          width: 230.0,
                          height: 300.0,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: <Widget>[
                              SizedBox(height: 20),
                              Text(
                                "Tap here to get back to list of selected games",
                                style: getMainTextSizeForTutorial(),
                              ),
                            ],
                          ),
                        )))),
          ]),
    );
    targets.add(
      TargetFocus(
        identify: "Search",
        keyTarget: searchKey,
        enableOverlayTab: true,
        color: Colors.purpleAccent,
        contents: [
          TargetContent(
              child: Container(
                  child: Align(
                      alignment: FractionalOffset.topRight,
                      child: SizedBox(
                        width: 230.0,
                        height: 300.0,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              "Tap here to start searching",
                              style: getMainTextSizeForTutorial(),
                            ),
                            Text(
                              "If you don't want to search in your browser, just start typing the name of the game.",
                              style: getTextStyleForSubText(),
                            )
                          ],
                        ),
                      ))))
        ],
      ),
    );
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => showTutorial(() => sharedPropWrapper.saveTutorialFlagWeb(true)));
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
