// ignore_for_file: unrelated_type_equality_checks

import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:nb_utils/nb_utils.dart';
import '/api/core_apis.dart';
import '/screens/Encounter/add_encounter/model/encounter_resp_model.dart';
import '../../../utils/app_common.dart';
import '../../../utils/common_base.dart';
import '../../../utils/constants.dart';
import '../../clinic/model/clinics_res_model.dart';
import '../../doctor/model/doctor_list_res.dart';
import '../model/encounters_list_model.dart';
import '../model/encounter_progress_model.dart';
import 'model/patient_model.dart';

class AddEncountersController extends GetxController {
  //TextFiled Controller
  final GlobalKey<FormState> addEncounterFormKey = GlobalKey();
  TextEditingController dateCont = TextEditingController();
  TextEditingController clinicCont = TextEditingController();
  TextEditingController doctorCont = TextEditingController();
  TextEditingController patientCont = TextEditingController();
  TextEditingController descriptionCont = TextEditingController();

  FocusNode dateFocus = FocusNode();
  FocusNode clinicFocus = FocusNode();
  FocusNode doctorFocus = FocusNode();
  FocusNode patientFocus = FocusNode();
  FocusNode descriptionFocus = FocusNode();

  //Error Clinic
  RxBool hasErrorFetchingClinic = false.obs;
  RxString errorMessageClinic = "".obs;
  //Error Doctor
  RxBool hasErrorFetchingDoctor = false.obs;
  RxString errorMessageDoctor = "".obs;
  //Error Patient
  RxBool hasErrorFetchingPatient = false.obs;
  RxString errorMessagePatient = "".obs;

  //Clinic
  Rx<Future<RxList<ClinicData>>> getClinics = Future(
    () => RxList<ClinicData>(),
  ).obs;
  RxBool isLoading = false.obs;
  RxInt page = 1.obs;
  RxList<ClinicData> clinicList = RxList();
  RxBool isLastPage = false.obs;
  Rx<ClinicData> selectClinic = ClinicData().obs;
  RxString searchClinic = "".obs;

  //Doctors
  Rx<Future<RxList<Doctor>>> doctorsFuture = Future(() => RxList<Doctor>()).obs;
  RxBool isDoctorsLoading = false.obs;
  RxList<Doctor> doctors = RxList();
  RxBool isDoctorsLastPage = false.obs;
  RxInt doctorsPage = 1.obs;
  Rx<Doctor> selectDoctor = Doctor().obs;
  RxString searchDoctor = "".obs;

  //Patient
  Rx<Future<RxList<PatientModel>>> patientFuture = Future(
    () => RxList<PatientModel>(),
  ).obs;
  RxBool isPatientLoading = false.obs;
  RxList<PatientModel> patientList = RxList();
  RxBool isPatientLastPage = false.obs;
  RxInt patientPage = 1.obs;
  Rx<PatientModel> selectPatient = PatientModel().obs;
  RxString searchPatient = "".obs;

  //Appointment (optional - for linking encounter to appointment)
  RxInt appointmentId = (-1).obs;

  //Save Encounter
  Rx<Future<Rx<EncounterResp>>> saveEncounterFuture = Future(
    () => EncounterResp().obs,
  ).obs;
  Rx<EncounterResp> encounterResp = EncounterResp().obs;

  //Edit Counter Details
  Rx<EncounterElement> editEncounterResp = EncounterElement().obs;

  //Encounter Progress for session/day-wise services
  Rx<EncounterProgressModel?> encounterProgress = Rx<EncounterProgressModel?>(
    null,
  );
  RxBool isLoadingProgress = false.obs;
  RxInt selectedAppointmentId = (-1).obs;

  // Method to fetch encounter progress
  Future<void> fetchEncounterProgress(int appointmentId) async {
    try {
      isLoadingProgress(true);
      selectedAppointmentId(appointmentId);

      final progress = await CoreServiceApis.getAppointmentEncounterProgress(
        appointmentId: appointmentId,
      );

      encounterProgress(progress);
    } catch (e) {
      log("Error fetching encounter progress: $e");
      encounterProgress(null);
    } finally {
      isLoadingProgress(false);
    }
  }

  // Check if more encounters can be created
  bool get canCreateEncounter {
    return encounterProgress.value?.canCreateMore ?? true;
  }

  // Get progress text
  String get progressText {
    final progress = encounterProgress.value;
    if (progress == null) return '';

    if (progress.encounterType == 'session') {
      return 'Session ${progress.existingEncounters}/${progress.totalRequired}';
    } else if (progress.encounterType == 'day') {
      return 'Day ${progress.existingEncounters}/${progress.totalRequired}';
    }

    return '';
  }

  @override
  void onReady() {
    selectClinic(selectedAppClinic.value);
    getClinicList();
    getPatientList();
    getArgument();
    super.onReady();
  }

  getArgument() {
    // Handle editing existing encounter
    if (Get.arguments != null && Get.arguments.length > 0) {
      if (Get.arguments[0] &&
          Get.arguments.length > 1 &&
          (Get.arguments[1] is EncounterElement)) {
        editEncounterResp(Get.arguments[1]);
        dateCont.text =
            editEncounterResp.value.encounterDate.dateInDMMMMyyyyFormat;
        descriptionCont.text = editEncounterResp.value.description;

        // If encounter has appointment_id, fetch progress
        if (editEncounterResp.value.appointmentId > 0) {
          appointmentId(editEncounterResp.value.appointmentId);
          fetchEncounterProgress(editEncounterResp.value.appointmentId);
        }
      }
      // Handle creating new encounter with appointment_id
      else if (!Get.arguments[0] &&
          Get.arguments.length > 1 &&
          Get.arguments[1] is int) {
        appointmentId(Get.arguments[1]);
        if (appointmentId.value > 0) {
          fetchEncounterProgress(appointmentId.value);
        }
      }
    }
  }

  getClinicList({bool showloader = true}) async {
    if (showloader) {
      isLoading(true);
    }
    await getClinics(
          CoreServiceApis.getClinicList(
            clinicList: clinicList,
            page: page.value,
            search: searchClinic.value,
            lastPageCallBack: (p0) {
              isLastPage(p0);
            },
          ),
        )
        .then((value) async {
          log("Value is ==> $value");
          clinicList(value);
          hasErrorFetchingClinic(false);
          if (editEncounterResp.value.clinicName.isNotEmpty) {
            for (var element in clinicList) {
              if (element.id == editEncounterResp.value.clinicId) {
                selectClinic(element);
                clinicCont.text = element.name;
              }
            }
            await getDoctors();
          }
        })
        .catchError((e) {
          hasErrorFetchingClinic(true);
          errorMessageClinic(e.toString());
          toast("Error: $e");
          log("getClinicList err: $e");
        })
        .whenComplete(() => isLoading(false));
  }

  getPatientList({bool showloader = true}) async {
    if (showloader) {
      isLoading(true);
    }
    await patientFuture(
          CoreServiceApis.getPatientsList(
            patientsList: patientList,
            page: page.value,
            clinicId:
                loginUserData.value.userRole.contains(EmployeeKeyConst.doctor)
                ? selectedAppClinic.value.id
                : null,
            search: searchPatient.value,
            lastPageCallBack: (p0) {},
          ),
        )
        .then((value) {
          hasErrorFetchingPatient(false);
          if (editEncounterResp.value.userName.isNotEmpty) {
            for (var element in patientList) {
              if (element.id == editEncounterResp.value.userId) {
                selectPatient(element);
                patientCont.text = element.fullName;
              }
            }
          }
        })
        .catchError((e) {
          hasErrorFetchingPatient(true);
          errorMessagePatient(e.toString());
          toast("Error: $e");
          log("getPatientsList err: $e");
        })
        .whenComplete(() => isLoading(false));
  }

  Future<void> getDoctors({bool showLoader = true}) async {
    if (showLoader) {
      isLoading(true);
    }
    await doctorsFuture(
          CoreServiceApis.getDoctors(
            page: doctorsPage.value,
            doctors: doctors,
            search: searchDoctor.value,
            clinicId: selectClinic.value.id,
            lastPageCallBack: (p0) {
              isDoctorsLastPage(p0);
            },
          ),
        )
        .then((value) {
          hasErrorFetchingDoctor(false);
          log('value.length ==> ${value.length}');
          if (editEncounterResp.value.doctorName.isNotEmpty) {
            for (var element in doctors) {
              if (element.doctorId == editEncounterResp.value.doctorId) {
                selectDoctor(element);
                doctorCont.text = element.fullName;
              }
            }
          }
        })
        .catchError((e) {
          hasErrorFetchingDoctor(true);
          errorMessageDoctor(e.toString());
          log("getDoctors error $e");
        })
        .whenComplete(() => isLoading(false));
  }

  saveEncounter({bool showloader = true}) async {
    Map<String, dynamic> request = {
      "encounter_date": dateCont.text.dateInyyyyMMddFormat.toString(),
      "clinic_id": selectClinic.value.id.toString(),
      "doctor_id":
          loginUserData.value.userRole.contains(EmployeeKeyConst.doctor)
          ? loginUserData.value.id
          : selectDoctor.value.doctorId.toString(),
      "user_id": selectPatient.value.id.toString(),
      "description": descriptionCont.text.isEmpty
          ? ""
          : descriptionCont.text.toString(),
    };

    // Add appointment_id if available
    if (appointmentId.value > 0) {
      request["appointment_id"] = appointmentId.value.toString();
    }

    if (showloader) {
      isLoading(true);
    }
    await saveEncounterFuture(
          CoreServiceApis.saveEncounter(
            request: request,
            encounterResp: encounterResp.value,
          ),
        )
        .then((value) {
          encounterResp(value.value);
          Get.back(result: true);
        })
        .catchError((e) {
          toast("Error: $e");
          log("getEncounterResp err: $e");
        })
        .whenComplete(() => isLoading(false));
  }

  //Update Encounter
  editEncounter({bool showloader = true}) async {
    Map<String, dynamic> request = {
      "encounter_date": dateCont.text.dateInyyyyMMddFormat.toString(),
      "clinic_id": selectClinic.value.id.toString(),
      "doctor_id":
          loginUserData.value.userRole.contains(EmployeeKeyConst.doctor)
          ? loginUserData.value.id
          : selectDoctor.value.doctorId.toString(),
      "user_id": selectPatient.value.id.toString(),
      "description": descriptionCont.text.toString(),
    };
    if (showloader) {
      isLoading(true);
    }
    await saveEncounterFuture(
          CoreServiceApis.editEncounter(
            request: request,
            id: editEncounterResp.value.id,
            encounterResp: encounterResp.value,
          ),
        )
        .then((value) {
          encounterResp(value.value);
          Get.back(result: true);
        })
        .catchError((e) {
          toast("Error: $e");
          log("getEncounterResp err: $e");
        })
        .whenComplete(() => isLoading(false));
  }
}
