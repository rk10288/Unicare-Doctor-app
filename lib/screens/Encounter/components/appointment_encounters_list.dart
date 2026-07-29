import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import '../model/encounter_progress_model.dart';

class AppointmentEncountersList extends StatelessWidget {
  final List<EncounterSummary> encounters;
  final String encounterType;

  const AppointmentEncountersList({
    Key? key,
    required this.encounters,
    required this.encounterType,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (encounters.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Previous Encounters',
          style: boldTextStyle(size: 16),
        ).paddingBottom(12),
        ...encounters.map((enc) {
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: enc.isCompleted ? Colors.green : Colors.orange,
                child: Icon(
                  enc.isCompleted ? Icons.check : Icons.pending,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              title: Text(
                encounterType == 'session'
                    ? 'Session ${enc.sessionNumber}'
                    : 'Day ${enc.dayNumber}',
                style: boldTextStyle(size: 14),
              ),
              subtitle: Text(
                enc.encounterDate,
                style: secondaryTextStyle(size: 12),
              ),
              trailing: Text(
                enc.isCompleted ? 'Completed' : 'Pending',
                style: primaryTextStyle(
                  size: 12,
                  color: enc.isCompleted ? Colors.green : Colors.orange,
                ),
              ),
            ),
          );
        }).toList(),
      ],
    ).paddingTop(16);
  }
}
