#!/usr/bin/env node

const fs = require('fs');
const path = require('path');

// Helper function to get the average of an array
function avg(arr) {
  if (arr.length === 0) return 0;
  return arr.reduce((sum, val) => sum + val, 0) / arr.length;
}

// Helper function to get the sum of an array
function sum(arr) {
  return arr.reduce((sum, val) => sum + val, 0);
}

// Helper function to parse date and extract day
function getDateString(dateStr) {
  return dateStr.split(' ')[0];
}

// Helper function to convert distance from meters to km
function metersToKm(meters) {
  return meters / 1000;
}

function processHealthData() {
  const dataDir = path.join(__dirname, '..', 'data', 'raw');
  const outputFile = path.join(__dirname, '..', 'data', 'dashboard.json');

  // Get all JSON files in the data/raw directory
  const files = fs.readdirSync(dataDir)
    .filter(file => file.endsWith('.json'))
    .sort(); // Sort by filename (which includes date)

  console.log(`Processing ${files.length} health data files...`);

  const dailyData = {};

  files.forEach(file => {
    console.log(`Processing ${file}...`);
    const filePath = path.join(dataDir, file);
    const data = JSON.parse(fs.readFileSync(filePath, 'utf8'));
    
    // Extract date from filename (HealthAutoExport-2026-02-02.json -> 2026-02-02)
    const fileDate = file.replace('HealthAutoExport-', '').replace('.json', '');
    
    if (!dailyData[fileDate]) {
      dailyData[fileDate] = {
        date: fileDate,
        steps: 0,
        distance: 0,
        activeEnergy: 0,
        exerciseMinutes: 0,
        restingHR: 0,
        avgHRV: 0,
        avgSpO2: 0,
        sleepTotal: 0,
        sleepDeep: 0,
        sleepREM: 0,
        sleepCore: 0,
        sleepAwake: 0,
        sleepStart: '',
        sleepEnd: '',
        respiratoryRate: 0,
        walkingSpeed: 0
      };
    }

    // Process metrics
    data.data.metrics.forEach(metric => {
      switch (metric.name) {
        case 'step_count':
          dailyData[fileDate].steps = Math.round(sum(metric.data.map(d => d.qty)));
          break;

        case 'distance_walking_running':
          dailyData[fileDate].distance = metersToKm(sum(metric.data.map(d => d.qty)));
          break;

        case 'active_energy':
          // Convert kJ to kcal (1 kcal = 4.184 kJ)
          dailyData[fileDate].activeEnergy = Math.round(sum(metric.data.map(d => d.qty)) / 4.184);
          break;

        case 'apple_exercise_time':
          dailyData[fileDate].exerciseMinutes = Math.round(sum(metric.data.map(d => d.qty)));
          break;

        case 'resting_heart_rate':
          const rhrs = metric.data.map(d => d.qty).filter(qty => qty > 0);
          dailyData[fileDate].restingHR = rhrs.length > 0 ? Math.round(avg(rhrs)) : 0;
          break;

        case 'heart_rate_variability':
          const hrvs = metric.data.map(d => d.qty).filter(qty => qty > 0);
          dailyData[fileDate].avgHRV = hrvs.length > 0 ? Math.round(avg(hrvs)) : 0;
          break;

        case 'blood_oxygen_saturation':
          const spo2s = metric.data.map(d => d.qty).filter(qty => qty > 0);
          dailyData[fileDate].avgSpO2 = spo2s.length > 0 ? Math.round(avg(spo2s)) : 0;
          break;

        case 'sleep_analysis':
          // Sleep data for night of fileDate-1 is in the file for fileDate
          if (metric.data && metric.data.length > 0) {
            const sleepData = metric.data[0]; // Usually just one sleep record per day
            dailyData[fileDate].sleepTotal = sleepData.totalSleep || 0;
            dailyData[fileDate].sleepDeep = sleepData.deep || 0;
            dailyData[fileDate].sleepREM = sleepData.rem || 0;
            dailyData[fileDate].sleepCore = sleepData.core || 0;
            dailyData[fileDate].sleepAwake = sleepData.awake || 0;
            dailyData[fileDate].sleepStart = sleepData.sleepStart || '';
            dailyData[fileDate].sleepEnd = sleepData.sleepEnd || '';
          }
          break;

        case 'respiratory_rate':
          const respiratoryRates = metric.data.map(d => d.qty).filter(qty => qty > 0);
          dailyData[fileDate].respiratoryRate = respiratoryRates.length > 0 ? 
            Math.round(avg(respiratoryRates) * 10) / 10 : 0;
          break;

        case 'walking_speed':
          const walkingSpeeds = metric.data.map(d => d.qty).filter(qty => qty > 0);
          dailyData[fileDate].walkingSpeed = walkingSpeeds.length > 0 ? 
            Math.round(avg(walkingSpeeds) * 100) / 100 : 0;
          break;
      }
    });
  });

  // Convert to array and sort by date
  const sortedData = Object.values(dailyData).sort((a, b) => a.date.localeCompare(b.date));

  // Write to output file
  const outputData = {
    lastUpdated: new Date().toISOString(),
    data: sortedData
  };

  fs.writeFileSync(outputFile, JSON.stringify(outputData, null, 2));
  console.log(`Dashboard data written to ${outputFile}`);
  console.log(`Processed ${sortedData.length} days of data`);
}

// Run if called directly
if (require.main === module) {
  processHealthData();
}

module.exports = { processHealthData };