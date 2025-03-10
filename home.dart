import 'dart:ffi';

import 'package:fan_fiesta/config/ad_helper.dart';
import 'package:fan_fiesta/data/models/match_preview_model.dart';
import 'package:fan_fiesta/presentation/blocs/Home/bloc/home_bloc.dart';
import 'package:fan_fiesta/presentation/blocs/ScoreBoard/scoreboard_bloc.dart';
import 'package:fan_fiesta/presentation/screens/Home/no_live_fixtures.dart';
import 'package:fan_fiesta/presentation/screens/MatchSummary/match_summary.dart';
import 'package:fan_fiesta/presentation/widgets/Commons/custom_padding.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:lottie/lottie.dart';
import 'package:fan_fiesta/presentation/widgets/ArenaCard/arena_card.dart';
import 'package:fan_fiesta/presentation/widgets/FavouriteTeamCard/favourite_team_card.dart';
import 'package:fan_fiesta/presentation/widgets/NewsCard/news_card.dart';

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<Home> {
  BannerAd? _ad;
  bool add1Loaded = false;
  BannerAd? _ad2;
  bool add2Loaded = false;

  int selectedTab = 0;
  String favoriteTeamLogo = 'lib/assets/logoPng/arsenal_logo.png';
  List<Map<String, String>> teamLogos = [
    {
      'homeTeamLogo': 'lib/assets/logoPng/arsenal_logo.png',
      'awayTeamLogo': 'lib/assets/logoPng/manchester_city.png',
    },
    {
      'homeTeamLogo': 'lib/assets/logoPng/csk_logo.png',
      'awayTeamLogo': 'lib/assets/logoPng/rcb_logo.png',
    },
  ];
  ValueNotifier<double> topNewsContainerHeight = ValueNotifier<double>(140);
  ValueNotifier<double> teamNewsContainerHeight = ValueNotifier<double>(140);
  ValueNotifier<double> nationalTeamNewsContainerHeight =
      ValueNotifier<double>(140);

  @override
  void initState() {
    homeBloc.add(HomeInitialEvent());
    super.initState();

    BannerAd(
      adUnitId: AdHelper.bannerAdUnitId,
      size: AdSize(width: 360, height: 240),
      request: AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          setState(() {
            _ad = ad as BannerAd;
          });
        },
        onAdFailedToLoad: (ad, error) {
          // Releases an ad resource when it fails to load
          ad.dispose();
          print('Ad load failed (code=${error.code} message=${error.message})');
        },
      ),
    ).load();

    BannerAd(
      adUnitId: AdHelper.bannerAdUnit2,
      size: AdSize(width: 360, height: 240),
      request: AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          setState(() {
            _ad2 = ad as BannerAd;
          });
        },
        onAdFailedToLoad: (ad, error) {
          // Releases an ad resource when it fails to load
          ad.dispose();
          print('Ad load failed (code=${error.code} message=${error.message})');
        },
      ),
    ).load();
  }

  HomeBloc homeBloc = HomeBloc();
  ScoreBoardBloc scoreBoardBloc = ScoreBoardBloc();

  void updateContainerHeight(double newHeight, String newsBlocCode) {
    switch (newsBlocCode) {
      case "TOP":
        topNewsContainerHeight.value = newHeight;
        break;
      case "CLUB":
        teamNewsContainerHeight.value = newHeight;
        break;
      case "COUNTRY":
        nationalTeamNewsContainerHeight.value = newHeight;
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<HomeBloc, HomeState>(
      bloc: homeBloc,
      listenWhen: (previous, current) => current is HomeActionState,
      buildWhen: (previous, current) => current is! HomeActionState,
      listener: (context, state) {
        if (state is HomeNavigateToMatchArenaState) {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => MatchSummary(
                        matchPreview: state.matchPreview,
                      )));
        }
        if (state is UpdateNewsContainerHeight) {
          updateContainerHeight(state.height, state.newsBlocCode);
        }
      },
      builder: (context, state) {
        switch (state.runtimeType) {
          case HomeLoadingState:
            return const Center(
              child: CircularProgressIndicator(),
            );
          case HomeLoadedSuccessState:
            final successState = state as HomeLoadedSuccessState;
            var matchPreviewList = successState.fixtures;
            if (matchPreviewList != null && matchPreviewList.length > 0) {
              matchPreviewList
                  .sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
            }
            var topNews = successState.topNews;
            var clubNews = successState.clubNews;
            var nationalNews = successState.nationalNews;
            topNewsContainerHeight = ValueNotifier<double>(
                getInitialContainerHeight(topNews.length));
            teamNewsContainerHeight = ValueNotifier<double>(
                getInitialContainerHeight(clubNews.length));
            nationalTeamNewsContainerHeight = ValueNotifier<double>(
                getInitialContainerHeight(nationalNews.length));
            var favClubId = successState.favClubId;
            var favNationalTeamId = successState.favNationId;
            var favClubImg = successState.favClubImgUrl;
            var favNationalImg = successState.favNationImgUrl;
            MatchPreview? favoriteTeam;
            bool isFavouriteTeamPlaying = false;
            if (matchPreviewList != null && matchPreviewList.isNotEmpty) {
              isFavouriteTeamPlaying = matchPreviewList.any((item) =>
                  (item.homeTeam.id == favClubId ||
                      item.awayTeam.id == favClubId) ||
                  (item.homeTeam.id == favNationalTeamId ||
                      item.awayTeam.id == favNationalTeamId));

              if (isFavouriteTeamPlaying) {
                favoriteTeam = matchPreviewList.firstWhere((item) =>
                    (item.homeTeam.id == favClubId ||
                        item.awayTeam.id == favClubId) ||
                    (item.homeTeam.id == favNationalTeamId ||
                        item.awayTeam.id == favNationalTeamId));
              }
            }
            return Scaffold(
                appBar: AppBar(
                    title: Row(
                      children: [
                        Text(
                          "ScoreBuddy",
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.blueAccent,
                          ),
                        ),
                        CustomPadding(
                          widget: Image.asset(
                              'lib/assets/logoPng/scorebuddyLogo.png',
                              height: 45,
                              width: 45),
                          padding: EdgeInsets.fromLTRB(10, 0, 0, 0),
                        )
                      ],
                    ),
                    automaticallyImplyLeading: false),
                body: ListView(
                  children: [
                    if (matchPreviewList != null && matchPreviewList.isNotEmpty)
                      Padding(
                        padding:
                            EdgeInsets.all(5.0), // Adjust the padding as needed
                        child: Text(
                          "Live Matches",
                          style: TextStyle(
                            fontSize: 20, // Increase the font size
                            fontWeight: FontWeight.bold, // Make the text bold
                            color: Colors.black, // Change the color
                          ),
                        ),
                      ),
                    if (matchPreviewList != null && matchPreviewList.isNotEmpty)
                      SizedBox(
                        height: MediaQuery.of(context).size.height *
                            0.15, // Set your desired height here
                        width: double.infinity,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: matchPreviewList
                              .length, // Replace with your number of cards
                          itemBuilder: (context, index) {
                            return ArenaCard(
                              matchPreview: matchPreviewList[index],
                              onClick: () {
                                homeBloc.add(LiveArenaClickEvent(
                                    matchPreview: matchPreviewList[index]));
                                // homeBloc.add(YourEvent());
                              },
                            );
                          },
                        ),
                      ),
                    isFavouriteTeamPlaying && favoriteTeam != null
                        ? SizedBox(
                            height: MediaQuery.of(context).size.height * 0.3,
                            child: Padding(
                              padding: const EdgeInsets.all(
                                  5.0), // Adjust the padding as needed
                              child: FavouriteTeamCard(
                                homeTeamLogo: favoriteTeam.homeTeam
                                    .imagePath!, // Use the index to select the image
                                awayTeamLogo: favoriteTeam.awayTeam.imagePath!,
                                notes: favoriteTeam.notes.isEmpty
                                    ? favoriteTeam.matchStatus
                                    : favoriteTeam.notes,
                                onClick: () {
                                  homeBloc.add(LiveArenaClickEvent(
                                      matchPreview: favoriteTeam!));
                                },
                              ), // Replace with your FavoriteTeamCard widget
                            ),
                          )
                        : const SizedBox.shrink(),
                    if (_ad != null)
                      ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxHeight: 240,
                            minHeight: 240,
                          ),
                          child: AdWidget(ad: _ad!)),
                    if (clubNews.isNotEmpty)
                      ValueListenableBuilder<double>(
                        valueListenable: teamNewsContainerHeight,
                        builder: (context, containerHeight, child) {
                          return Container(
                              height: containerHeight,
                              child: NewsCard(
                                newsArticles: clubNews,
                                newsHeader: "Your Team News",
                                headerImage: favClubImg,
                                homeBloc: homeBloc,
                                newsBlocCode: "CLUB",
                              ));
                        },
                      ),
                    if (nationalNews.isNotEmpty)
                      ValueListenableBuilder<double>(
                        valueListenable: nationalTeamNewsContainerHeight,
                        builder: (context, containerHeight, child) {
                          return Container(
                              height: containerHeight,
                              child: NewsCard(
                                newsArticles: nationalNews,
                                newsHeader: "National Team News",
                                headerImage: favNationalImg,
                                homeBloc: homeBloc,
                                newsBlocCode: "COUNTRY",
                              ));
                        },
                      ),
                    SizedBox(
                      height: 10,
                    ),
                    if (_ad2 != null)
                      ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxHeight: 240,
                            minHeight: 240,
                          ),
                          child: AdWidget(ad: _ad2!)),
                    SizedBox(
                      height: 10,
                    ),
                    if (topNews.isNotEmpty)
                      ValueListenableBuilder<double>(
                        valueListenable: topNewsContainerHeight,
                        builder: (context, containerHeight, child) {
                          return Container(
                              height: containerHeight,
                              child: NewsCard(
                                newsArticles: topNews,
                                newsHeader: "Top Cricket News",
                                headerImage: favClubImg,
                                homeBloc: homeBloc,
                                newsBlocCode: "TOP",
                              ));
                        },
                      ),
                  ],
                ));
          case HomeNoLiveFixturesState:
            return const NoLiveFixtures();
          default:
            return const SizedBox();
        }
      },
    );
  }

  double getInitialContainerHeight(int articleCount) {
    if (articleCount < 5) {
      return (70 + (articleCount * 140)).toDouble();
    } else
      return 770.toDouble();
  }
}
