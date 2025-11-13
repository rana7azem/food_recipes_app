import 'package:flutter/material.dart';
import 'package:food_recipes_app/models/onboard.dart';
import 'package:food_recipes_app/widgets/custom_btn.dart';
import 'package:food_recipes_app/widgets/bottom_nav_bar.dart';
import 'package:lottie/lottie.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = PageController();
    final mq = MediaQuery.sizeOf(context);
    final list = [
      //onboarding 1
      Onboard(
          title: 'Select Your The Recipe You Desire',
          subtitle:
              'Select From Our Wide Range of Recipes Or Add Your Own Recipe!',
          lottie: 'Select Your Recipe'),

      //onboarding 2
       Onboard(
        title: 'Make Your Shopping List',
        lottie: 'Make Your List',
        subtitle:
            'Make Your Shopping List Based On The Recipe You Selected!',
      ),
        //onboarding 3
       Onboard(
        title: 'Enjoy Your Lovely Meal',
        lottie: 'Enjoy Your Meal',
        subtitle:
            'Stay Creative & Enjoy Your Lovely Meal!',
      ),
    ];

    return Scaffold(
      body: PageView.builder(
        controller: c,
        itemCount: list.length,
        itemBuilder: (ctx, ind) {
          final isLast = ind == list.length - 1;

          return Column(
            children: [
              //lottie
              Lottie.asset('assets/animations/${list[ind].lottie}.json',
                  height: mq.height * .6, width: isLast ? mq.width * .7 : null),

              //title
              Text(
                list[ind].title,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .5),
              ),

              //for adding some space
              SizedBox(height: mq.height * .015),

              //subtitle
              SizedBox(
                width: mq.width * .7,
                child: Text(
                  list[ind].subtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 13.5,
                      letterSpacing: .5,
                      color: Colors.grey,
                ),
              ),
              ),

              const Spacer(),

              //dots

              Wrap(
                spacing: 10,
                children: List.generate(
                    list.length,
                    (i) => Container(
                          width: i == ind ? 15 : 10,
                          height: 8,
                          decoration: BoxDecoration(
                              color: i == ind ? Colors.blue : Colors.grey,
                              borderRadius:
                                  const BorderRadius.all(Radius.circular(5))),
                        )),
              ),

              const Spacer(),

              //button
              CustomBtn(
                  onTap: () {
                    if (isLast) {
                      Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (_) => const BottomNavBar()));
                    } else {
                      c.nextPage(
                          duration: const Duration(milliseconds: 600),
                          curve: Curves.ease);
                    }
                  },
                  text: isLast ? 'Finish' : 'Next'),

              const Spacer(flex: 2),
            ],
          );
        },
      ),
    );
  }
}