import 'dart:async';

import 'package:flutter/material.dart';
import 'package:abherbs_flutter/entity/observation.dart';
import 'package:abherbs_flutter/utils/utils.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'package:abherbs_flutter/generated/i18n.dart';

class ObservationMap extends StatefulWidget {
  final Locale myLocale;
  final Observation observation;
  final String mode;
  ObservationMap(this.myLocale, this.observation, this.mode);

  @override
  _ObservationMapState createState() => _ObservationMapState();
}

class _ObservationMapState extends State<ObservationMap> {
  GoogleMapController _mapController;
  DateFormat _dateFormat;
  DateFormat _timeFormat;
  MarkerId _markerId;
  Map<MarkerId, Marker> _markers = <MarkerId, Marker>{};

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  void _onAddMarkerButtonPressed() {
    final Marker marker = _markers[_markerId];
    setState(() {
      _markers[_markerId] = marker.copyWith(
        positionParam: LatLng(
          _mapController.cameraPosition.target.latitude,
          _mapController.cameraPosition.target.longitude,
        ),
      );
    });
  }

  void _onSaveButtonPressed(BuildContext context) {
    Marker marker = _markers[_markerId];
    Navigator.pop(context, LatLng(marker.position.latitude, marker.position.longitude));
  }

  @override
  void initState() {
    super.initState();
    _dateFormat = new DateFormat.yMMMMd(widget.myLocale.toString());
    _timeFormat = new DateFormat.Hms(widget.myLocale.toString());
    _markerId = MarkerId(widget.observation.plant);
    _markers = <MarkerId, Marker>{};
    _markers[_markerId] = Marker(
      markerId: _markerId,
      //draggable: true,
      position: LatLng(
        widget.observation.latitude ?? 0.0,
        widget.observation.longitude ?? 0.0,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    Future<String> nameF = translationCache.containsKey(widget.observation.plant)
        ? Future<String>(() {
            return translationCache[widget.observation.plant];
          })
        : translationsReference
            .child(getLanguageCode(widget.myLocale.languageCode))
            .child(widget.observation.plant)
            .child(firebaseAttributeLabel)
            .once()
            .then((DataSnapshot snapshot) {
            if (snapshot.value != null) {
              translationCache[widget.observation.plant] = snapshot.value;
              return snapshot.value;
            } else {
              return null;
            }
          });

    var widgets = <Widget>[];
    widgets.add(GoogleMap(
      onMapCreated: _onMapCreated,
      trackCameraPosition: true,
      initialCameraPosition: CameraPosition(
        target: LatLng(widget.observation.latitude ?? 0.0, widget.observation.longitude ?? 0.0),
        zoom: widget.observation.latitude == null || widget.observation.longitude == null ? 1 : 13,
      ),
      markers: Set<Marker>.of(_markers.values),
    ));

    if (widget.mode == mapModeEdit) {
      widgets.add(Padding(
        padding: const EdgeInsets.all(16.0),
        child: Align(
          alignment: Alignment.topRight,
          child: FloatingActionButton(
            heroTag: 'add_marker',
            onPressed: _onAddMarkerButtonPressed,
            materialTapTargetSize: MaterialTapTargetSize.padded,
            child: const Icon(Icons.add_location, size: 36.0),
          ),
        ),
      ));
      widgets.add(Padding(
        padding: const EdgeInsets.all(16.0),
        child: Align(
          alignment: Alignment.bottomRight,
          child: FloatingActionButton(
            heroTag: 'save',
            onPressed: () {
              _onSaveButtonPressed(context);
            },
            materialTapTargetSize: MaterialTapTargetSize.padded,
            child: const Icon(Icons.save, size: 36.0),
          ),
        ),
      ));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).observation),
      ),
      body: Column(
        children: [
          FutureBuilder<String>(
              future: nameF,
              builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
                String labelLocal = widget.observation.plant;
                if (snapshot.connectionState == ConnectionState.done) {
                  if (snapshot.data != null) {
                    labelLocal = snapshot.data;
                  }
                }
                return ListTile(
                  title: Text(
                    labelLocal,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.0),
                  ),
                  subtitle: labelLocal != widget.observation.plant ? Text(widget.observation.plant) : null,
                  trailing: Column(
                    children: [
                      Text(_dateFormat.format(widget.observation.date)),
                      Text(_timeFormat.format(widget.observation.date)),
                    ],
                  ),
                );
              }),
          Expanded(
            child: Stack(
              children: widgets,
            ),
          ),
        ],
      ),
    );
  }
}