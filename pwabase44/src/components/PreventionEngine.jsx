/**
 * Prevention Engine
 * Intelligent system for generating personalized prevention recommendations
 * Based on age, gender, risk groups, pregnancy status, and current guidelines
 */

import { base44 } from "@/api/base44Client";
import { differenceInYears, differenceInWeeks, addMonths, addYears } from "date-fns";

/**
 * Comprehensive vaccination recommendations based on STIKO guidelines
 */
export const getVaccinationRecommendations = async (user, existingVaccinations = []) => {
  const age = user.date_of_birth 
    ? differenceInYears(new Date(), new Date(user.date_of_birth))
    : null;

  if (!age) return [];

  const recommendations = [];

  // Get last vaccination dates
  const getLastVaccination = (vaccineName) => {
    const vacc = existingVaccinations
      .filter(v => v.vaccine_name === vaccineName)
      .sort((a, b) => new Date(b.date_given) - new Date(a.date_given))[0];
    return vacc?.date_given ? new Date(vacc.date_given) : null;
  };

  // Standard vaccinations for all ages
  const standardVaccines = [
    {
      name: "Tetanus",
      interval: 10,
      description: "Wundstarrkrampf-Schutz",
      importance: "critical"
    },
    {
      name: "Diphtherie",
      interval: 10,
      description: "Schutz vor Diphtherie",
      importance: "critical"
    },
    {
      name: "Pertussis (Keuchhusten)",
      interval: 10,
      description: "Schutz vor Keuchhusten",
      importance: "high"
    }
  ];

  for (const vaccine of standardVaccines) {
    const lastVacc = getLastVaccination(vaccine.name);
    if (!lastVacc || differenceInYears(new Date(), lastVacc) >= vaccine.interval) {
      recommendations.push({
        type: "vaccination",
        vaccine: vaccine.name,
        reason: lastVacc 
          ? `Auffrischung fällig (letzte Impfung vor ${differenceInYears(new Date(), lastVacc)} Jahren)`
          : "Grundimmunisierung empfohlen",
        urgency: lastVacc && differenceInYears(new Date(), lastVacc) > vaccine.interval + 2 ? "high" : "medium",
        description: vaccine.description,
        dueDate: lastVacc ? addYears(lastVacc, vaccine.interval) : new Date()
      });
    }
  }

  // Age-specific recommendations

  // Children and adolescents (0-17)
  if (age < 18) {
    const childVaccines = [
      { name: "MMR (Masern, Mumps, Röteln)", ages: [1, 2], description: "Schutz vor Masern, Mumps und Röteln" },
      { name: "Varizellen (Windpocken)", ages: [1, 2], description: "Schutz vor Windpocken" },
      { name: "HPV", ages: [9, 10, 11, 12, 13, 14], description: "Schutz vor HPV (Gebärmutterhalskrebs)", gender: "Weiblich" },
      { name: "Meningokokken", ages: [1, 2, 12], description: "Schutz vor Meningokokken-Erkrankungen" },
      { name: "Pneumokokken", ages: [0, 1, 2], description: "Schutz vor Pneumokokken" }
    ];

    for (const vaccine of childVaccines) {
      if (vaccine.gender && user.gender !== vaccine.gender) continue;
      if (vaccine.ages.includes(age)) {
        const lastVacc = getLastVaccination(vaccine.name);
        if (!lastVacc) {
          recommendations.push({
            type: "vaccination",
            vaccine: vaccine.name,
            reason: `Empfohlene Impfung für ${age}-Jährige`,
            urgency: "high",
            description: vaccine.description,
            ageGroup: "child"
          });
        }
      }
    }
  }

  // Influenza (Grippe) - annual for risk groups and 60+
  if (age >= 60 || user.risk_groups?.includes("chronisch_krank") || user.is_pregnant) {
    const lastFlu = getLastVaccination("Influenza (Grippe)");
    const currentYear = new Date().getFullYear();
    const lastFluYear = lastFlu ? new Date(lastFlu).getFullYear() : null;
    
    if (!lastFlu || lastFluYear < currentYear) {
      recommendations.push({
        type: "vaccination",
        vaccine: "Influenza (Grippe)",
        reason: age >= 60 
          ? "Jährlich empfohlen für über 60-Jährige"
          : user.is_pregnant
          ? "Empfohlen während der Schwangerschaft"
          : "Jährlich empfohlen für Risikogruppen",
        urgency: "medium",
        description: "Schutz vor saisonaler Grippe",
        seasonal: true,
        bestTime: "September - November"
      });
    }
  }

  // COVID-19
  const lastCovid = getLastVaccination("COVID-19");
  if (!lastCovid || differenceInMonths(new Date(), lastCovid) >= 12) {
    recommendations.push({
      type: "vaccination",
      vaccine: "COVID-19",
      reason: age >= 60 || user.risk_groups?.length > 0
        ? "Auffrischung empfohlen für Risikogruppen"
        : "Auffrischung nach 12 Monaten empfohlen",
      urgency: age >= 60 ? "high" : "medium",
      description: "Schutz vor COVID-19"
    });
  }

  // Shingles (Gürtelrose) - 60+
  if (age >= 60) {
    const lastShingles = getLastVaccination("Gürtelrose");
    if (!lastShingles) {
      recommendations.push({
        type: "vaccination",
        vaccine: "Gürtelrose",
        reason: "Empfohlen ab 60 Jahren",
        urgency: "medium",
        description: "Schutz vor Gürtelrose (Herpes Zoster)",
        requiresDoses: 2
      });
    }
  }

  // Pneumokokken - 60+ and risk groups
  if (age >= 60 || user.risk_groups?.includes("chronisch_krank")) {
    const lastPneumo = getLastVaccination("Pneumokokken");
    if (!lastPneumo || differenceInYears(new Date(), lastPneumo) >= 6) {
      recommendations.push({
        type: "vaccination",
        vaccine: "Pneumokokken",
        reason: age >= 60 ? "Empfohlen ab 60 Jahren" : "Empfohlen für Risikogruppen",
        urgency: "medium",
        description: "Schutz vor Pneumokokken-Erkrankungen"
      });
    }
  }

  // FSME (Tick-borne encephalitis) - for endemic areas
  const lastFSME = getLastVaccination("FSME (Zecken)");
  if (!lastFSME || differenceInYears(new Date(), lastFSME) >= 3) {
    recommendations.push({
      type: "vaccination",
      vaccine: "FSME (Zecken)",
      reason: "Empfohlen in Risikogebieten",
      urgency: "low",
      description: "Schutz vor Frühsommer-Meningoenzephalitis",
      optional: true,
      note: "Besonders wichtig bei Aufenthalt in FSME-Risikogebieten"
    });
  }

  return recommendations.sort((a, b) => {
    const urgencyOrder = { high: 0, medium: 1, low: 2 };
    return urgencyOrder[a.urgency] - urgencyOrder[b.urgency];
  });
};

/**
 * Screening and checkup recommendations based on age and gender
 */
export const getScreeningRecommendations = async (user, existingScreenings = []) => {
  const age = user.date_of_birth 
    ? differenceInYears(new Date(), new Date(user.date_of_birth))
    : null;

  if (!age) return [];

  const recommendations = [];

  // Cancer screenings

  // Skin cancer screening (35+, every 2 years)
  if (age >= 35) {
    recommendations.push({
      type: "screening",
      name: "Hautkrebsvorsorge",
      frequency: "Alle 2 Jahre",
      reason: "Früherkennung von Hautkrebs",
      urgency: "medium",
      ageGroup: "35+"
    });
  }

  // Women's health
  if (user.gender === "Weiblich") {
    // Cervical cancer (20-34: annual, 35+: every 3 years)
    if (age >= 20) {
      recommendations.push({
        type: "screening",
        name: "Gebärmutterhalskrebs-Vorsorge",
        frequency: age < 35 ? "Jährlich" : "Alle 3 Jahre",
        reason: "Früherkennung von Gebärmutterhalskrebs",
        urgency: "high",
        specialty: "Gynäkologie"
      });
    }

    // Breast cancer screening (50-69: every 2 years)
    if (age >= 50 && age <= 69) {
      recommendations.push({
        type: "screening",
        name: "Mammographie",
        frequency: "Alle 2 Jahre",
        reason: "Früherkennung von Brustkrebs",
        urgency: "high",
        specialty: "Gynäkologie/Radiologie"
      });
    }
  }

  // Men's health
  if (user.gender === "Männlich") {
    // Prostate cancer (45+)
    if (age >= 45) {
      recommendations.push({
        type: "screening",
        name: "Prostata-Vorsorge",
        frequency: "Jährlich",
        reason: "Früherkennung von Prostatakrebs",
        urgency: "medium",
        specialty: "Urologie"
      });
    }
  }

  // Colorectal cancer (50+)
  if (age >= 50) {
    recommendations.push({
      type: "screening",
      name: "Darmkrebsvorsorge (Koloskopie)",
      frequency: "Alle 10 Jahre oder jährlicher Stuhltest",
      reason: "Früherkennung von Darmkrebs",
      urgency: "high",
      specialty: "Gastroenterologie"
    });
  }

  // Cardiovascular screening (35+)
  if (age >= 35) {
    recommendations.push({
      type: "checkup",
      name: "Gesundheits-Check-up",
      frequency: "Alle 3 Jahre",
      reason: "Früherkennung von Herz-Kreislauf- und Nierenerkrankungen, Diabetes",
      urgency: "medium",
      includes: ["Blutdruck", "Blutzucker", "Cholesterin", "Urin"]
    });
  }

  return recommendations;
};

/**
 * Pregnancy-specific recommendations
 */
export const getPregnancyRecommendations = async (user) => {
  if (!user.is_pregnant || !user.pregnancy_due_date) return [];

  const dueDate = new Date(user.pregnancy_due_date);
  const conceptionDate = addMonths(dueDate, -9);
  const currentWeek = Math.floor(differenceInWeeks(new Date(), conceptionDate));

  const recommendations = [];

  // Standard pregnancy checkups
  const checkupSchedule = [
    { weeks: [8, 12, 16, 20, 24, 28, 30, 32, 34, 36, 37, 38, 39, 40], type: "Vorsorgeuntersuchung" },
    { weeks: [11, 12, 13], type: "Ersttrimester-Screening" },
    { weeks: [19, 20, 21, 22], type: "Organ-Ultraschall" },
    { weeks: [24, 25, 26, 27, 28], type: "Glukosetoleranztest (bei Bedarf)" },
    { weeks: [35, 36, 37], type: "B-Streptokokken-Test" }
  ];

  for (const checkup of checkupSchedule) {
    for (const week of checkup.weeks) {
      if (currentWeek <= week && currentWeek >= week - 2) {
        recommendations.push({
          type: "pregnancy_checkup",
          name: checkup.type,
          week: week,
          reason: `Empfohlene Untersuchung in Woche ${week}`,
          urgency: currentWeek >= week ? "high" : "medium",
          dueDate: addWeeks(conceptionDate, week)
        });
      }
    }
  }

  // Vaccinations during pregnancy
  recommendations.push({
    type: "vaccination",
    vaccine: "Influenza (Grippe)",
    reason: "Empfohlen während der Schwangerschaft",
    urgency: "medium",
    trimester: "Jedes Trimester möglich"
  });

  if (currentWeek >= 28) {
    recommendations.push({
      type: "vaccination",
      vaccine: "Pertussis (Keuchhusten)",
      reason: "Empfohlen ab der 28. Schwangerschaftswoche",
      urgency: "high",
      trimester: "3. Trimester"
    });
  }

  // Hebamme recommendation
  if (currentWeek < 20) {
    recommendations.push({
      type: "general",
      name: "Hebamme suchen",
      reason: "Frühzeitige Suche nach Hebamme empfohlen",
      urgency: "high",
      note: "Hebammen sind oft früh ausgebucht"
    });
  }

  // Birth preparation course
  if (currentWeek >= 25 && currentWeek <= 32) {
    recommendations.push({
      type: "general",
      name: "Geburtsvorbereitungskurs",
      reason: "Empfohlen zwischen Woche 28-32",
      urgency: "medium",
      note: "Unterstützt bei der Vorbereitung auf die Geburt"
    });
  }

  return recommendations.sort((a, b) => {
    const urgencyOrder = { high: 0, medium: 1, low: 2 };
    return urgencyOrder[a.urgency] - urgencyOrder[b.urgency];
  });
};

/**
 * Generate all recommendations for a user
 */
export const generateAllRecommendations = async (user) => {
  try {
    // Fetch existing data
    const [vaccinations, screenings] = await Promise.all([
      base44.entities.Vaccination.list().catch(() => []),
      base44.entities.Appointment.filter({ 
        status: "Abgeschlossen",
        reason: { $regex: "Vorsorge|Screening|Check" }
      }).catch(() => [])
    ]);

    const [vaccinationRecs, screeningRecs, pregnancyRecs] = await Promise.all([
      getVaccinationRecommendations(user, vaccinations),
      getScreeningRecommendations(user, screenings),
      user.is_pregnant ? getPregnancyRecommendations(user) : Promise.resolve([])
    ]);

    return {
      vaccinations: vaccinationRecs,
      screenings: screeningRecs,
      pregnancy: pregnancyRecs,
      total: vaccinationRecs.length + screeningRecs.length + pregnancyRecs.length
    };
  } catch (error) {
    console.error("Error generating recommendations:", error);
    return { vaccinations: [], screenings: [], pregnancy: [], total: 0 };
  }
};

// Helper function
const differenceInMonths = (date1, date2) => {
  return differenceInYears(date1, date2) * 12 + 
    (date1.getMonth() - date2.getMonth());
};

const addWeeks = (date, weeks) => {
  const result = new Date(date);
  result.setDate(result.getDate() + weeks * 7);
  return result;
};

export default {
  getVaccinationRecommendations,
  getScreeningRecommendations,
  getPregnancyRecommendations,
  generateAllRecommendations
};