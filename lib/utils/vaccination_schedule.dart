import 'package:flutter/material.dart';

class VaccinationSchedule {
  static List<VaccineScheduleItem> getVaccinationsForAge(int ageInMonths) {
    // Convert age from years to months if needed, or just use months
    // Assumes age is in months
    int months = ageInMonths;

    if (months == 0) {
      return [
        VaccineScheduleItem(
          vaccine: "BCG",
          ageRange: "At Birth",
          remarks: "As soon as possible after birth",
          recommended: true,
        ),
        VaccineScheduleItem(
          vaccine: "Hepatitis B (Birth dose)",
          ageRange: "At Birth",
          remarks: "As soon as possible after birth",
          recommended: true,
        ),
        VaccineScheduleItem(
          vaccine: "OPV-0",
          ageRange: "At Birth",
          remarks: "As soon as possible after birth",
          recommended: true,
        ),
      ];
    } else if (months <= 6) {
      // 6 weeks
      return [
        VaccineScheduleItem(
          vaccine: "DTP (1st)",
          ageRange: "6 Weeks",
          remarks: "Start of primary series",
          recommended: true,
        ),
        VaccineScheduleItem(
          vaccine: "IPV (1st)",
          ageRange: "6 Weeks",
          remarks: "Start of primary series",
          recommended: true,
        ),
        VaccineScheduleItem(
          vaccine: "Hep B (2nd)",
          ageRange: "6 Weeks",
          remarks: "Start of primary series",
          recommended: true,
        ),
        VaccineScheduleItem(
          vaccine: "Hib (1st)",
          ageRange: "6 Weeks",
          remarks: "Start of primary series",
          recommended: true,
        ),
        VaccineScheduleItem(
          vaccine: "Rotavirus (1st)",
          ageRange: "6 Weeks",
          remarks: "Start of primary series",
          recommended: true,
        ),
        VaccineScheduleItem(
          vaccine: "PCV (1st)",
          ageRange: "6 Weeks",
          remarks: "Start of primary series",
          recommended: true,
        ),
      ];
    } else if (months <= 10) {
      // 10 weeks
      return [
        VaccineScheduleItem(
          vaccine: "DTP (2nd)",
          ageRange: "10 Weeks",
          remarks: "Continue primary vaccination",
          recommended: true,
        ),
        VaccineScheduleItem(
          vaccine: "IPV (2nd)",
          ageRange: "10 Weeks",
          remarks: "Continue primary vaccination",
          recommended: true,
        ),
        VaccineScheduleItem(
          vaccine: "Hib (2nd)",
          ageRange: "10 Weeks",
          remarks: "Continue primary vaccination",
          recommended: true,
        ),
        VaccineScheduleItem(
          vaccine: "Rotavirus (2nd)",
          ageRange: "10 Weeks",
          remarks: "Continue primary vaccination",
          recommended: true,
        ),
        VaccineScheduleItem(
          vaccine: "PCV (2nd)",
          ageRange: "10 Weeks",
          remarks: "Continue primary vaccination",
          recommended: true,
        ),
      ];
    } else if (months <= 14) {
      // 14 weeks
      return [
        VaccineScheduleItem(
          vaccine: "DTP (3rd)",
          ageRange: "14 Weeks",
          remarks: "Complete primary series",
          recommended: true,
        ),
        VaccineScheduleItem(
          vaccine: "IPV (3rd)",
          ageRange: "14 Weeks",
          remarks: "Complete primary series",
          recommended: true,
        ),
        VaccineScheduleItem(
          vaccine: "Hib (3rd)",
          ageRange: "14 Weeks",
          remarks: "Complete primary series",
          recommended: true,
        ),
        VaccineScheduleItem(
          vaccine: "Rotavirus (3rd)",
          ageRange: "14 Weeks",
          remarks: "Complete primary series",
          recommended: true,
        ),
        VaccineScheduleItem(
          vaccine: "PCV (3rd)",
          ageRange: "14 Weeks",
          remarks: "Complete primary series",
          recommended: true,
        ),
      ];
    } else if (months >= 9 && months <= 12) {
      // 9-12 months
      return [
        VaccineScheduleItem(
          vaccine: "MMR (1st)",
          ageRange: "9-12 Months",
          remarks: "Prevents measles, mumps, rubella, pneumonia",
          recommended: true,
        ),
        VaccineScheduleItem(
          vaccine: "PCV Booster",
          ageRange: "9-12 Months",
          remarks: "Prevents measles, mumps, rubella, pneumonia",
          recommended: true,
        ),
        VaccineScheduleItem(
          vaccine: "Hepatitis A (1st)",
          ageRange: "9-12 Months",
          remarks: "Prevents measles, mumps, rubella, pneumonia",
          recommended: true,
        ),
      ];
    } else if (months >= 15 && months <= 18) {
      // 15-18 months
      return [
        VaccineScheduleItem(
          vaccine: "DTP Booster-1",
          ageRange: "15-18 Months",
          remarks: "First booster phase",
          recommended: true,
        ),
        VaccineScheduleItem(
          vaccine: "IPV Booster",
          ageRange: "15-18 Months",
          remarks: "First booster phase",
          recommended: true,
        ),
        VaccineScheduleItem(
          vaccine: "Hib Booster",
          ageRange: "15-18 Months",
          remarks: "First booster phase",
          recommended: true,
        ),
        VaccineScheduleItem(
          vaccine: "MMR (2nd)",
          ageRange: "15-18 Months",
          remarks: "First booster phase",
          recommended: true,
        ),
        VaccineScheduleItem(
          vaccine: "Varicella (1st)",
          ageRange: "15-18 Months",
          remarks: "First booster phase",
          recommended: true,
        ),
      ];
    } else if (months >= 24 && months <= 36) {
      // 2 years
      return [
        VaccineScheduleItem(
          vaccine: "Typhoid Conjugate Vaccine",
          ageRange: "2 Years",
          remarks: "Prevents typhoid fever",
          recommended: true,
        ),
      ];
    } else if (months >= 48 && months <= 72) {
      // 4-6 years
      return [
        VaccineScheduleItem(
          vaccine: "DTP Booster-2",
          ageRange: "4-6 Years",
          remarks: "School entry booster",
          recommended: true,
        ),
        VaccineScheduleItem(
          vaccine: "IPV Booster",
          ageRange: "4-6 Years",
          remarks: "School entry booster",
          recommended: true,
        ),
        VaccineScheduleItem(
          vaccine: "MMR (3rd)",
          ageRange: "4-6 Years",
          remarks: "School entry booster",
          recommended: true,
        ),
        VaccineScheduleItem(
          vaccine: "Varicella (2nd)",
          ageRange: "4-6 Years",
          remarks: "School entry booster",
          recommended: true,
        ),
      ];
    } else if (months >= 120 && months <= 144) {
      // 10-12 years
      return [
        VaccineScheduleItem(
          vaccine: "Tdap/Td Booster",
          ageRange: "10-12 Years",
          remarks: "Adolescent protection",
          recommended: true,
        ),
        VaccineScheduleItem(
          vaccine: "HPV (for girls)",
          ageRange: "10-12 Years",
          remarks: "Adolescent protection",
          recommended: true,
        ),
      ];
    } else if (months >= 192 && months <= 216) {
      // 16-18 years
      return [
        VaccineScheduleItem(
          vaccine: "Td Booster",
          ageRange: "16-18 Years",
          remarks: "Reinforcement for lifelong protection",
          recommended: true,
        ),
      ];
    }

    // Default: return all vaccinations
    return getAllVaccinations();
  }

  static List<VaccineScheduleItem> getAllVaccinations() {
    return [
      VaccineScheduleItem(
        vaccine: "BCG",
        ageRange: "At Birth",
        remarks: "As soon as possible after birth",
        recommended: false,
      ),
      VaccineScheduleItem(
        vaccine: "Hepatitis B (Birth dose)",
        ageRange: "At Birth",
        remarks: "As soon as possible after birth",
        recommended: false,
      ),
      VaccineScheduleItem(
        vaccine: "OPV-0",
        ageRange: "At Birth",
        remarks: "As soon as possible after birth",
        recommended: false,
      ),
      VaccineScheduleItem(
        vaccine: "DTP",
        ageRange: "6, 10, 14 Weeks",
        remarks: "Primary series",
        recommended: false,
      ),
      VaccineScheduleItem(
        vaccine: "IPV",
        ageRange: "6, 10, 14 Weeks",
        remarks: "Primary series",
        recommended: false,
      ),
      VaccineScheduleItem(
        vaccine: "Hib",
        ageRange: "6, 10, 14 Weeks",
        remarks: "Primary series",
        recommended: false,
      ),
      VaccineScheduleItem(
        vaccine: "Rotavirus",
        ageRange: "6, 10, 14 Weeks",
        remarks: "Primary series",
        recommended: false,
      ),
      VaccineScheduleItem(
        vaccine: "PCV",
        ageRange: "6, 10, 14 Weeks, 9-12 Months",
        remarks: "Primary series and booster",
        recommended: false,
      ),
      VaccineScheduleItem(
        vaccine: "MMR",
        ageRange: "9-12 Months, 15-18 Months, 4-6 Years",
        remarks: "Prevents measles, mumps, rubella",
        recommended: false,
      ),
      VaccineScheduleItem(
        vaccine: "Hepatitis A",
        ageRange: "9-12 Months",
        remarks: "Prevents Hepatitis A",
        recommended: false,
      ),
      VaccineScheduleItem(
        vaccine: "Varicella",
        ageRange: "15-18 Months, 4-6 Years",
        remarks: "Prevents chickenpox",
        recommended: false,
      ),
      VaccineScheduleItem(
        vaccine: "Typhoid Conjugate Vaccine",
        ageRange: "2 Years",
        remarks: "Prevents typhoid fever",
        recommended: false,
      ),
      VaccineScheduleItem(
        vaccine: "Tdap/Td Booster",
        ageRange: "10-12 Years",
        remarks: "Adolescent protection",
        recommended: false,
      ),
      VaccineScheduleItem(
        vaccine: "HPV (for girls)",
        ageRange: "10-12 Years",
        remarks: "Adolescent protection",
        recommended: false,
      ),
      VaccineScheduleItem(
        vaccine: "Td Booster",
        ageRange: "16-18 Years",
        remarks: "Reinforcement for lifelong protection",
        recommended: false,
      ),
    ];
  }

  static int calculateAgeInMonths(DateTime dob) {
    final now = DateTime.now();
    int years = now.year - dob.year;
    int months = now.month - dob.month;
    
    if (months < 0) {
      years--;
      months += 12;
    }
    
    return (years * 12) + months;
  }
}

class VaccineScheduleItem {
  final String vaccine;
  final String ageRange;
  final String remarks;
  final bool recommended;

  VaccineScheduleItem({
    required this.vaccine,
    required this.ageRange,
    required this.remarks,
    required this.recommended,
  });
}

