import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:super_app/Layout/Cubit/cubit.dart';
import 'package:super_app/Layout/Cubit/states.dart';
import 'package:super_app/Layout/GeneralChat.dart';

class Social extends StatelessWidget {
  const Social({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child:BlocBuilder<AppCubit,AppCubitStates>(
        builder: (context,state) {
          AppCubit.get(context).tabBarIndexSwitcher(DefaultTabController.of(context).index);
          return Column(
            children: [
              TabBar(
                labelColor: Colors.black,
                unselectedLabelColor: Colors.grey,
                tabs: [
                  Tab(text: "Social"),
                  Tab(text: "Chat"),
                ],
              ),
              Expanded(
                child: TabBarView(
                    children: [
                    ListView.builder(
                    shrinkWrap:true,
                    itemCount:5,
                    itemBuilder: (context,index) {
                    return Column(
                    children: [
                    Container(
                    width: MediaQuery.sizeOf(context).width*0.95,
                    margin: EdgeInsets.only(top:20),
                    decoration: BoxDecoration(
                    borderRadius: BorderRadius.only(topLeft: Radius.circular(8) , topRight:Radius.circular(8) ),
                    color: HexColor("#F0EFF4"),
                    ),
                    child: Padding(
                    padding:EdgeInsets.only(left: 10,top:10,bottom: 5),
                    child: Column(
                    children: [
                    Row(
                    children: [
                    Container(
                    height: 35,
                    width: 35,
                    decoration:BoxDecoration(
                    color:Colors.white,
                    shape: BoxShape.circle,
                    ),
                    child: SvgPicture.asset("assets/person.svg"),
                    ),

                    SizedBox(width:10,),
                    Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                    Text("Omar Yasser",style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w900 , fontSize: 12),),
                    Text("1d" ,style: GoogleFonts.plusJakartaSans(height: 0.8,fontWeight: FontWeight.w300 , fontSize: 12), ),
                    ],
                    )
                    ],
                    ),
                    SizedBox(height: 3,),
                    Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Text("Important announcement regarding the upcoming community event this weekend. Please make sure to RSVP by Friday!" ,style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w500 , fontSize: 12 , color: Colors.black), )),
                    ],
                    ),
                    ),
                    ),
                    Container(
                    width: MediaQuery.sizeOf(context).width*0.95,
                    height: 220,
                    color: Colors.black,
                    ),



                    Container(
                    width: MediaQuery.sizeOf(context).width*0.95,
                    decoration: BoxDecoration(
                    color: HexColor("#F0EFF4"),
                    borderRadius: BorderRadius.only(bottomLeft: Radius.circular(8) , bottomRight:Radius.circular(8) ),
                    ),

                    child: Column(
                    children: [
                    //<---------------------Comments and Likes Indicators -------------------->
                    Padding(
                    padding: EdgeInsets.symmetric(horizontal: MediaQuery.sizeOf(context).width*0.04 , vertical: 4),
                    child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                    Text("comments",
                    style: GoogleFonts.plusJakartaSans(
                    fontSize:12,
                    fontWeight: FontWeight.w500 ,
                    color:HexColor("#1c1e21").withAlpha(170)),),
                    ],
                    ),
                    ),
                    Divider(
                    indent:MediaQuery.sizeOf(context).width*0.04,
                    endIndent:MediaQuery.sizeOf(context).width*0.04,
                    height: 1.1,
                    color: Colors.black12,
                    ),
                    Padding(

                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                    MaterialButton(
                    onPressed: (){},
                    child:Row(
                    spacing: 5,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                    Icon(Icons.thumb_up_alt_outlined , color:HexColor("#1c1e21").withAlpha(170)),
                    Text("Like"),
                    ],),
                    ),
                    MaterialButton(
                    onPressed: (){},
                    child:Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    spacing: 5,
                    children: [
                    Icon(Icons.chat_outlined ,color:HexColor("#1c1e21").withAlpha(170)),
                    Text("comment"),
                    ],),
                    ),
                    MaterialButton(
                    onPressed: (){},
                    child:Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    spacing: 5,
                    children: [
                    Icon(Icons.mobile_screen_share , color:HexColor("#1c1e21").withAlpha(170)),
                    Text("share"),
                    ],),
                    ),


                    ],
                    ),
                    ),
                    ],
                    ),
                    ),

                    ],
                    );
                    }
                    ),
                    Generalchat(),
                    ],
                    ),
              ),
            ],
          );
        }
      )

    );
  }
}

