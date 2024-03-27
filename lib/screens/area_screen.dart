import 'dart:math';
import 'package:lottie/lottie.dart';
import '../widgets/image_dialog.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../utils/physics.dart';
import '../viewmodels/game_viewmodel.dart';
import '../widgets/base_scaffold.dart';
import '../widgets/score_bar.dart';
import '../widgets/word_item.dart';
import '../widgets/help_button.dart';
import '../services/notification_service.dart';

part 'mixin/area_screen_mixin.dart';

class AreaScreen extends StatelessWidget {
  const AreaScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<GameViewModel>();
    return BaseScaffold(
      showLeaf: true,
      withPadding: false,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        floatingActionButton: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            HelpButton(
              helpText: vm.isLastWord()
                  ? 'Открыть случайное слово. Нельзя открыть последнее слово'
                  : 'Открыть случайное слово. Уберите курсор из ячейки',
            ),
            HelpButton(
              word: true,
              helpText: vm.isLastWord()
                  ? 'Открыть выбранное слово. Нельзя открыть последнее слово'
                  : 'Открыть выбранное слово. Выберете ячейку',
            ),
            const SizedBox(
              height: 66,
            ),
          ],
        ),
        appBar: AppBar(
          automaticallyImplyLeading: false,
          elevation: 0,
          toolbarHeight: 76.0,
          flexibleSpace: const ScoreBar(
            withPadding: true,
            showLevel: true,
            prevScreen: 'Level',
          ),
          backgroundColor: Colors.transparent,
        ),
        body: GestureDetector(
          onTap: () {
            FocusScope.of(context).requestFocus(FocusNode());
            vm.clearActiveWord();
          },
          child: const NestedScrollWidget(),
        ),
      ),
    );
  }
}

class NestedScrollWidget extends StatefulWidget {
  const NestedScrollWidget({Key? key}) : super(key: key);

  @override
  __NestedScrollState createState() => __NestedScrollState();
}

class __NestedScrollState extends State<NestedScrollWidget> with AreaScreenMixin{

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<GameViewModel>();
    final groups = vm.groups;
    final animVisible = (vm.getLevelIndex() == 1);

    ensureScroll(context);
    final advContainerWidth = MediaQuery.of(context).size.width - wordWidth;

    return NotificationListener<ScrollEndNotification>(
      onNotification: (end) {
        setState(() {
          widthOffset = _scrollCtrl.offset;
        });
        return true;
      },
      child: Stack(
        children: [
          SingleChildScrollView(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: CustomScrollPhysics(itemDimension: wordWidth),
              controller: _scrollCtrl,
              child: Row(
                children: [
                  ...groups.map((group) {
                    final index = vm.groups.indexOf(group);
                    final page = (widthOffset / wordWidth).floor();

                    var itemCounts = vm.groups[page > 0 ? page : 0].length;
                    return Container(
                      height: (itemCounts + 1) * itemHeight,
                      constraints: BoxConstraints(
                        minHeight: MediaQuery.of(context).size.height - 70,
                      ),
                      child: Stack(
                        children: [
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ...group.map((word) {
                                final key =
                                    word == vm.scrollableWord ? dataKey : null;
                                if (key != null) {
                                  vm.scrollKey = key;
                                }
                                final showEndLeaf =
                                    (widthOffset / wordWidth).floor() <= index;
                                final showStartLeaf =
                                    (widthOffset / wordWidth).floor() == index;
                                return AnimatedBuilder(
                                  animation: _scrollCtrl,
                                  builder: (context, child) {
                                    final page = max(
                                        (widthOffset / wordWidth).floor(), 0);
                                    final position = _recalculateOffset(
                                      maxItems: groups[page].length,
                                      depth: word.depth,
                                    );

                                    return AnimatedContainer(
                                      width: wordWidth,
                                      height: itemHeight,
                                      duration:
                                          const Duration(milliseconds: 150),
                                      margin: EdgeInsets.only(
                                        right: 0,
                                        top: position,
                                        bottom: position,
                                      ),
                                      child: child,
                                    );
                                  },
                                  child: WordItem(
                                    key: key,
                                    word: word,
                                    showEndLeaf: showEndLeaf,
                                    showStartLeaf: showStartLeaf,
                                  ),
                                );
                              }).toList(),
                              Container(
                                height: 66,
                              ),
                            ],
                          ),
                          if (animVisible &&
                              (index == 0) &&
                              vm.saveLottieShowValue)
                            Positioned.fill(
                              left: wordWidth / 5,
                              bottom: itemHeight * 1.2,
                              child: GestureDetector(
                                onTap: () {
                                  if (context
                                      .read<GameViewModel>()
                                      .showWrongAnswerDialog) {
                                    // wrongAnswer();
                                    return;
                                  }
                                  FocusScope.of(context)
                                      .requestFocus(FocusNode());
                                  showDialog(
                                    context: context,
                                    barrierColor: Colors.black45,
                                    builder: (ctx) => ImageDialog(
                                      word: group.first,
                                      vm: context.read<GameViewModel>(),
                                    ),
                                  );
                                },
                                child: IgnorePointer(
                                  child: Lottie.asset(
                                    height: 1.8 * itemHeight,
                                    'assets/lottie/Animation.json',
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  }).toList(),
                  Container(width: advContainerWidth),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 40,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black87]),
              ),
            ),
          ),
          Positioned(
            bottom: 20,
            left: 10,
            right: 10,
            child: Center(
              child: AnimatedSmoothIndicator(
                activeIndex: max(
                    ((_scrollCtrl.hasClients ? _scrollCtrl.offset : 0) /
                            wordWidth)
                        .floor(),
                    0),
                count: groups.length,
                effect: const ExpandingDotsEffect(
                  dotWidth: 12,
                  dotHeight: 8,
                  expansionFactor: 2,
                  dotColor: Color.fromRGBO(169, 126, 74, 1),
                  activeDotColor: Color.fromRGBO(255, 244, 205, 1),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  double _recalculateOffset({required int maxItems, required int depth}) {
    final totalItemsHeight = maxItems * itemHeight;
    final totalDepthHeight = totalItemsHeight - (depth * itemHeight);
    final offsetValue = max<double>((totalDepthHeight / depth) / 2, 0.0);

    return offsetValue;
  }
}
