import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme{
    static ThemeData get darkTheme {
        return ThemeData (
            brightness: Brightness.dark,
            scaffolBackgroundColor: AppColors.background,
            primaryColor: AppColours.neongreen , 
            colorScheme : const ColourScheme.dark (
                primary : AppColors.neongreen , 
                secondary : AppColors.solarAmber , 
                surface : AppColors.surface , 
                background : AppColors.background ,
            ),

            appBarTheme : const AppBarTheme (
                backgroundColor: AppColors.background , 
                elecvation : 0 ,
                centerTitle : true ,
                titleTextStyle : TextStyle (
                    color : AppColors.textPrimary,
                    fontSize : 20,
                    fontWeight : FontWeight.bold,
                ),
            ),
        );
    }
}