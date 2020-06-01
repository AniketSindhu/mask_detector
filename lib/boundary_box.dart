import 'package:flutter/material.dart';

class BoundaryBox extends StatelessWidget {
  final List<dynamic> results;
  final int previewH;
  final int previewW;
  final double screenH;
  final double screenW;

  BoundaryBox(this.results, this.previewH, this.previewW, this.screenH, this.screenW);

  @override
  Widget build(BuildContext context) {

    List<Widget> _renderStrings() {
      return results.map((re) {
        return Stack(
          children: <Widget>[
            Positioned(
              left: (screenW/4),
              bottom: -(screenH-80),
              width: screenW,
              height: screenH,
              child: Text(
                "${re["label"]=='0 with_mask'?"Mask detected":"Mask not detected"} ${(re["confidence"] * 100).toStringAsFixed(0)}%",
                style: TextStyle(
                  backgroundColor: Colors.white,
                  color:re["label"]=='0 with_mask'? Colors.green:Colors.red,
                  fontSize: 20.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          Positioned(
            left: 30,
            top: 30,
            width: screenW,
            height: screenH,
            child: Text(
              "Detection only on veritcal camera feed",
            style: TextStyle(
              backgroundColor: Colors.black,
              color:Colors.purple,
              fontSize: 20.0,
              fontWeight: FontWeight.bold,
            ),
          ),
        )
      ],
      );
      }).toList();
    }

      
    return Stack(
      children: _renderStrings(),
    );
  }
}