import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nb_utils/nb_utils.dart';
import '/utils/common_base.dart';
import '../../../generated/assets.dart';
import 'medicine_list_controller.dart';

class SearchMedicineWidget extends StatelessWidget {
  final String? hintText;
  final Function(String)? onFieldSubmitted;
  final Function()? onTap;
  final Function()? onClearButton;
  final MedicinesListController medicinesListCont;

  const SearchMedicineWidget({
    super.key,
    this.hintText,
    this.onTap,
    this.onFieldSubmitted,
    this.onClearButton,
    required this.medicinesListCont,
  });

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      controller: medicinesListCont.searchMedicinesCont,
      textFieldType: TextFieldType.OTHER,
      textInputAction: TextInputAction.done,
      textStyle: primaryTextStyle(),
      onTap: onTap,
      onFieldSubmitted: onFieldSubmitted,
      onChanged: (p0) {
        medicinesListCont.isSearchMedicinesText(
          medicinesListCont.searchMedicinesCont.text.trim().isNotEmpty,
        );
        medicinesListCont.searchMedicinesStream.add(p0);
      },
      suffix: Obx(
        () => appCloseIconButton(
          context,
          onPressed: () {
            if (onClearButton != null) {
              onClearButton!.call();
            }
            hideKeyboard(context);
            medicinesListCont.searchMedicinesCont.clear();
            medicinesListCont.isSearchMedicinesText(
              medicinesListCont.searchMedicinesCont.text.trim().isNotEmpty,
            );
            medicinesListCont.medicinePage(1);
            medicinesListCont.getMedicineList();
          },
          size: 11,
        ).visible(medicinesListCont.isSearchMedicinesText.value),
      ),
      decoration: inputDecorationWithOutBorder(
        context,
        hintText: hintText ?? "Search Medicines Here",
        filled: true,
        fillColor: context.cardColor,
        prefixIcon: commonLeadingWid(
          imgPath: Assets.iconsIcSearch,
          size: 18,
        ).paddingAll(14),
      ),
    );
  }
}
