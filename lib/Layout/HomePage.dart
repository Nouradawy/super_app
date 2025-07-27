import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:super_app/Layout/Cubit/cubit.dart';
import 'package:super_app/Layout/Cubit/states.dart';

import '../Components/Constants.dart';
import '../Components/Social.dart';
import 'Profile.dart';

class HomePage extends StatelessWidget {
  TextEditingController Search = TextEditingController();
  List<Map<String,dynamic>> services= [{
  "icon": "assets/Svg/maintenance.svg",
  "Name": "Maintenance",
    "icon color":Colors.indigo.shade600,
    "icon bg":Colors.indigo.shade100,
    "Background" :Colors.indigo.shade50,
    "text Color":Colors.indigo.shade900
},
    {
      "icon": "assets/Svg/security.svg",
      "Name": "Security",
      "icon color":Colors.purple.shade600,
      "icon bg":Colors.purple.shade100,
      "Background" :Colors.purple.shade50,
      "text Color":Colors.purple.shade900
    },

    {
      "icon": "assets/Svg/cleaning.svg",
      "Name": "Cleaning",
      "icon color":Colors.teal.shade600,
      "icon bg":Colors.teal.shade100,
      "Background" :Colors.teal.shade50,
      "text Color":Colors.teal.shade900
    }
];

   HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return  BlocBuilder<AppCubit,AppCubitStates>(
      builder: (BuildContext context, state) {
        return Scaffold(
            backgroundColor:Colors.white,
          appBar: AppBar(
            backgroundColor:Colors.white,
            title:Text("Community Hub",style: GoogleFonts.plusJakartaSans(),),
            actions:[IconButton(onPressed: (){
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => Profile()),
              );
            }, icon: Icon(Icons.settings))],
          ),
          body: NestedScrollView(
              headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled){

                return [

                  SliverAppBar(
                  backgroundColor: Colors.white,
                  expandedHeight: MediaQuery.of(context).size.height*0.27,
                  flexibleSpace: FlexibleSpaceBar(
                    background:Column(
                      children: [
                        //Searchbar
                        Container(
                          padding: EdgeInsets.only(left: MediaQuery.of(context).size.width*0.075 , right:MediaQuery.of(context).size.width*0.075 ),
                          child: defaultTextForm(
                              context,
                              controller:Search,
                              keyboardType: TextInputType.text,
                              preIcon: Icons.search_outlined
                          ),
                        ),
                        SizedBox(
                          height:20,
                        ),

                        //<-----------------ListView for Services---------------->
                        Container(
                          margin:EdgeInsets.only(left:MediaQuery.of(context).size.width*0.075),
                          height: 120,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            clipBehavior: Clip.none,
                            itemCount:services.length,
                            itemBuilder: (context,index){
                              final service = services[index];
                              return Container(
                                width: 120,
                                margin: EdgeInsets.only(right:10),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  color: service["Background"],
                                ),
                                child:Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    spacing: 15,
                                    children: [
                                      Container(
                                        padding: EdgeInsets.all(12),
                                        width: 50,
                                        height: 50,
                                        decoration: BoxDecoration(
                                          shape:BoxShape.circle,
                                          color: service["icon bg"]
                                        ),
                                        child: SvgPicture.asset(
                                            
                                            colorFilter:ColorFilter.mode(
                                              service["icon color"],
                                              BlendMode.srcIn,
                                            )
                                            ,
                                            service['icon']),
                                      ),
                                      SizedBox(
                                          width: 100,
                                          child: Text(service['Name'] ,textAlign: TextAlign.center, style: GoogleFonts.plusJakartaSans(fontSize:13,fontWeight: FontWeight.bold , color: service["text Color"]
                                          ),)),

                                    ]
                                ),
                              );
                            },
                          ),
                        ),
                        SizedBox(
                          height: 20,
                        ),


                      ],
                    ),
                  ),
                )];
              }, body: Social(),

          )
        );
      }
    );
  }
}

