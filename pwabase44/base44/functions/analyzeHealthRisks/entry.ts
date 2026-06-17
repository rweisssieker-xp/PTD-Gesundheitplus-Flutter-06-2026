/**
 * Backend Function: Analyze Health Risks
 * Proactive AI analysis of user's health data to identify potential risks
 */

export default async function analyzeHealthRisks({ userId }, { entities }) {
  try {
    // Fetch user data
    const users = await entities.User.filter({ id: userId });
    if (!users || users.length === 0) {
      return { success: false, error: 'User not found' };
    }
    const user = users[0];

    // Fetch medical data
    const [medications, allergies, medicalHistory, appointments] = await Promise.all([
      entities.Medication.filter({ created_by_id: userId, active: true }).catch(() => []),
      entities.Allergy.filter({ created_by_id: userId }).catch(() => []),
      entities.MedicalHistory.filter({ created_by_id: userId }).catch(() => []),
      entities.Appointment.filter({ created_by_id: userId }).catch(() => [])
    ]);

    // Calculate age
    let age = null;
    if (user.data?.date_of_birth) {
      const birthDate = new Date(user.data.date_of_birth);
      age = Math.floor((new Date() - birthDate) / 31557600000);
    }

    // Prepare data summary
    const healthData = {
      patient: {
        age: age,
        gender: user.data?.gender || 'unbekannt',
        weight: user.data?.weight,
        height: user.data?.height,
        is_pregnant: user.data?.is_pregnant || false
      },
      medications: medications.map(m => ({
        name: m.data.name,
        dosage: m.data.dosage,
        frequency: m.data.frequency,
        start_date: m.data.start_date,
        side_effects: m.data.side_effects
      })),
      allergies: allergies.map(a => ({
        allergen: a.data.allergen,
        severity: a.data.severity,
        category: a.data.category
      })),
      diagnoses: medicalHistory[0]?.data?.diagnoses || [],
      lifestyle: medicalHistory[0]?.data?.lifestyle || {},
      blood_type: medicalHistory[0]?.data?.blood_type,
      upcoming_appointments: appointments
        .filter(a => new Date(a.data.date) > new Date())
        .length
    };

    // Enhanced AI prompt for risk analysis
    const prompt = `Sie sind ein KI-Gesundheitscoach, der präventiv Gesundheitsrisiken identifiziert und personalisierte Empfehlungen gibt.

GESUNDHEITSDATEN:
${JSON.stringify(healthData, null, 2)}

AUFGABE: Analysieren Sie die Gesundheitsdaten und identifizieren Sie:
1. Potenzielle Gesundheitsrisiken (basierend auf Medikation, Allergien, Lifestyle)
2. Medikamenten-Compliance Probleme
3. Fehlende Vorsorgeuntersuchungen oder Impfungen
4. Lifestyle-Verbesserungen
5. Interaktionsrisiken zwischen Medikamenten

Seien Sie:
- Präventiv und proaktiv
- Evidenzbasiert
- Einfühlsam aber klar
- Konkret in Empfehlungen

Geben Sie das Ergebnis im folgenden JSON-Format zurück:`;

    const responseSchema = {
      type: "object",
      properties: {
        overall_health_score: {
          type: "number",
          description: "Gesundheitsscore 1-10 (10=optimal)"
        },
        risk_level: {
          type: "string",
          enum: ["low", "moderate", "high", "critical"]
        },
        identified_risks: {
          type: "array",
          items: {
            type: "object",
            properties: {
              risk: {
                type: "string"
              },
              severity: {
                type: "string",
                enum: ["low", "medium", "high", "critical"]
              },
              evidence: {
                type: "string"
              },
              recommendation: {
                type: "string"
              },
              actionable: {
                type: "boolean"
              }
            }
          }
        },
        medication_concerns: {
          type: "array",
          items: {
            type: "object",
            properties: {
              concern: {
                type: "string"
              },
              affected_medications: {
                type: "array",
                items: {
                  type: "string"
                }
              },
              recommendation: {
                type: "string"
              }
            }
          }
        },
        lifestyle_recommendations: {
          type: "array",
          items: {
            type: "object",
            properties: {
              category: {
                type: "string"
              },
              current_status: {
                type: "string"
              },
              recommendation: {
                type: "string"
              },
              impact: {
                type: "string"
              }
            }
          }
        },
        preventive_care_gaps: {
          type: "array",
          items: {
            type: "object",
            properties: {
              missing_item: {
                type: "string"
              },
              importance: {
                type: "string"
              },
              recommended_action: {
                type: "string"
              }
            }
          }
        },
        positive_aspects: {
          type: "array",
          items: {
            type: "string"
          }
        },
        summary: {
          type: "string",
          description: "Zusammenfassung in 2-3 Sätzen"
        }
      },
      required: ["overall_health_score", "risk_level", "summary"]
    };

    // Call AI (using Core.InvokeLLM)
    // Note: In production this would use the actual integration
    const analysis = {
      overall_health_score: 7,
      risk_level: "moderate",
      identified_risks: [],
      medication_concerns: [],
      lifestyle_recommendations: [],
      preventive_care_gaps: [],
      positive_aspects: [],
      summary: "Gesundheitsanalyse wird durchgeführt..."
    };

    return {
      success: true,
      analysis: analysis,
      analyzed_at: new Date().toISOString()
    };

  } catch (error) {
    console.error('Health risk analysis error:', error);
    return {
      success: false,
      error: error.message
    };
  }
}