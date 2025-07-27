// src/validateReading.ts
export type CakeReading = { batchId: number; temperature: number; humidity: number };

export const maxTemp = 20;
export const minTemp = -7;
export const MAX_HUMIDITY = 50;
export const MIN_HUMIDITY = 20;

export function violates(r: CakeReading): string | null {
  if (r.temperature > maxTemp)      return "TEMP_HIGH";
  if (r.temperature < minTemp)      return "TEMP_LOW";
  if (r.humidity    > MAX_HUMIDITY) return "HUM_HIGH";
  if (r.humidity    < MIN_HUMIDITY) return "HUM_LOW";
  return null;
}