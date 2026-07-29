// ignore_for_file: depend_on_referenced_packages

import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nb_utils/nb_utils.dart';
import '../../../main.dart';
import '../../../utils/app_common.dart';
import '../../../utils/common_base.dart';
import '../../../utils/constants.dart';
import '../../../api/auth_apis.dart';
import '../../../utils/local_storage.dart';
import '../../clinic/model/clinics_res_model.dart';
import '../model/login_roles_model.dart';
import 'sign_in_controller.dart';

class SignUpController extends GetxController {
  RxBool isLoading = false.obs;

  final GlobalKey<FormState> signUpformKey = GlobalKey();

  RxBool agree = false.obs;
  RxBool isAcceptedTc = false.obs;
  TextEditingController emailCont = TextEditingController();
  TextEditingController phoneCodeCont = TextEditingController();
  TextEditingController mobileCont = TextEditingController();
  TextEditingController fisrtNameCont = TextEditingController();
  TextEditingController lastNameCont = TextEditingController();
  TextEditingController passwordCont = TextEditingController();
  TextEditingController userTypeCont = TextEditingController();
  TextEditingController clinicCenterCont = TextEditingController();

  FocusNode emailFocus = FocusNode();
  FocusNode phoneCodeFocus = FocusNode();
  FocusNode mobileFocus = FocusNode();
  FocusNode fisrtNameFocus = FocusNode();
  FocusNode lastNameFocus = FocusNode();
  FocusNode passwordFocus = FocusNode();
  FocusNode userTypeFocus = FocusNode();
  FocusNode clinicCenterFocus = FocusNode();

  Rx<Country> pickedPhoneCode = defaultCountry.obs;

  Rx<LoginRoleData> selectedLoginRole = LoginRoleData().obs;

  Rx<ClinicData> selectedClinic = ClinicData().obs;
  RxString emailError = ''.obs;
  RxString passwordError = ''.obs;

  @override
  void onInit() {
    if (!appConfigs.value.isMultiVendor) {
      loginRoles.removeWhere((item) => item.userType == EmployeeKeyConst.vendor);
    } else if (loginRoles.indexWhere((item) => item.userType == EmployeeKeyConst.vendor) == -1) {
      loginRoles.add(vendorLoginRole);
    }
    // Listen for email field focus change
    emailFocus.addListener(() {
      if (!emailFocus.hasFocus) {
        validateEmail();
      }
    });

    super.onInit();
  }

  RxBool passContHasFocus = false.obs;
  RxBool hasUppercase = false.obs;
  RxBool hasNumber = false.obs;
  RxBool hasSpecial = false.obs;
  RxBool hasLetter = false.obs;

  void checkPasswordRules(String password) {
    hasUppercase.value = RegExp(r'[A-Z]').hasMatch(password);
    hasNumber.value = RegExp(r'[0-9]').hasMatch(password);
    hasSpecial.value = RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password);
    hasLetter.value = RegExp(r'[a-z]').hasMatch(password);
  }

  void validateEmail() {
    if (emailCont.text.isEmpty) {
      emailError.value = 'Email is required';
    } else if (!emailCont.text.isEmail) {
      emailError.value = 'Please enter a valid email address';
    } else {
      emailError.value = ''; // Clear error if valid
    }
  }

  selectClinics({required ClinicData clinic}) {
    clinicCenterCont.clear();
    selectedClinic(clinic);
    clinicCenterCont.text = clinic.name;
  }

  saveForm() async {
    if (selectedLoginRole.value.id.isNegative) {
      toast(locale.value.pleaseSelectRoleToRegister);
    } else if (selectedClinic.value.id.isNegative && !selectedLoginRole.value.userType.contains(EmployeeKeyConst.vendor)) {
      toast(locale.value.pleaseSelectClinicToRegister);
    } else if (isAcceptedTc.value) {
      isLoading(true);
      hideKeyBoardWithoutContext();
      Map<String, dynamic> req = {
        UserKeys.email: emailCont.text.trim(),
        UserKeys.firstName: fisrtNameCont.text.trim(),
        UserKeys.lastName: lastNameCont.text.trim(),
        UserKeys.password: passwordCont.text.trim(),
        UserKeys.mobile: "+${mobileCont.text.trim().formatPhoneNumber(pickedPhoneCode.value.phoneCode)}",
        if (!selectedClinic.value.id.isNegative) "clinic_id": selectedClinic.value.id,
        UserKeys.userType: selectedLoginRole.value.userType,
      };

      await AuthServiceApis.createUser(request: req).then((value) async {
        try {
          final SignInController sCont = Get.find();
          sCont.emailCont.text = emailCont.text.trim();
          sCont.passwordCont.text = passwordCont.text.trim();
          sCont.selectedLoginRole(selectedLoginRole.value);
          selectedAppClinic(selectedClinic.value);
          loginUserData.value.selectedClinic = selectedClinic.value;
          setValueToLocal(SharedPreferenceConst.USER_DATA, loginUserData.toJson());
        } catch (e) {
          log('E: $e');
          toast(e.toString(), print: true);
        }
        Get.back();
        toast(value.message.toString(), print: true);
      }).catchError((e) {
        toast(e.toString(), print: true);
      }).whenComplete(() => isLoading(false));
    } else {
      toast(locale.value.pleaseAcceptTermsAnd);
    }
  }
}
