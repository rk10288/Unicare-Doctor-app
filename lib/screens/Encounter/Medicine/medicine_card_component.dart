import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '/utils/app_common.dart';
import '/utils/price_widget.dart';
import 'package:nb_utils/nb_utils.dart';
import '/utils/colors.dart';
import 'medicine_list_controller.dart';
import 'medicine_resp_model.dart';

class MedicineCardWidget extends StatelessWidget {
  final Medicine medicineData;
  final MedicinesListController medicinesListCont;
  const MedicineCardWidget({
    super.key,
    required this.medicineData,
    required this.medicinesListCont,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        medicinesListCont.selectedMedicine(medicineData);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: boxDecorationDefault(
          borderRadius: BorderRadius.circular(6),
          color: context.cardColor,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /* CachedImageWidget(
              url: medicineData.clinicImage,
              width: 52,
              radius: 6,
              fit: BoxFit.cover,
              height: 52,
            ),
            16.width, */
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(
                  medicineData.name,
                  style: boldTextStyle(
                    size: 14,
                    color: isDarkMode.value ? null : darkGrayTextColor,
                  ),
                ),
                2.height,
                Row(
                  children: [
                    Row(
                      children: [
                        Text(
                          "Dosage: ",
                          style: primaryTextStyle(
                            size: 12,
                            color: dividerColor,
                          ),
                        ),
                        2.width,
                        Text(
                          medicineData.dosage,
                          style: boldTextStyle(
                            size: 12,
                            color: isDarkMode.value ? null : darkGrayTextColor,
                          ),
                        ),
                      ],
                    ),
                    24.width,
                    Row(
                      children: [
                        Text(
                          "Form: ",
                          style: primaryTextStyle(
                            size: 12,
                            color: dividerColor,
                          ),
                        ),
                        2.width,
                        Text(
                          medicineData.form.name,
                          style: boldTextStyle(
                            size: 12,
                            color: isDarkMode.value ? null : darkGrayTextColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                2.height,
                Row(
                  children: [
                    Text(
                      "Expiry Date: ",
                      style: primaryTextStyle(size: 12, color: dividerColor),
                    ),
                    2.width,
                    Text(
                      medicineData.expiryDate,
                      style: boldTextStyle(
                        size: 12,
                        color: isDarkMode.value ? null : darkGrayTextColor,
                      ),
                    ),
                  ],
                ),
                2.height,
                Row(
                  children: [
                    Text(
                      "Price: ",
                      style: primaryTextStyle(size: 12, color: dividerColor),
                    ),
                    2.width,
                    PriceWidget(
                      price: medicineData.sellingPrice.toDouble(),
                      size: 14,
                      isBoldText: true,
                    ),
                  ],
                ),
              ],
            ).expand(),
            12.width,
            Obx(
              () => Radio(
                value: medicineData.id,
                groupValue: medicinesListCont.selectedMedicine.value.id,
                onChanged: (val) async {
                  medicinesListCont.selectedMedicine(medicineData);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
