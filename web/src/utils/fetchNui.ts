/**
 * Wrapper für NUI Callbacks.
 * Sendet Daten an den FiveM-Client (Lua).
 */
export async function fetchNui<T = any>(eventName: string, data?: any): Promise<T> {
  const options = {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json; charset=UTF-8',
    },
    body: JSON.stringify(data),
  };

  const resourceName = (window as any).GetParentResourceName
    ? (window as any).GetParentResourceName()
    : 'access_control';

  try {
    const resp = await fetch(`https://${resourceName}/${eventName}`, options);
    return await resp.json();
  } catch (error) {
    // Wenn wir im Browser (außerhalb von FiveM) entwickeln, Mock-Daten zurückgeben
    console.warn(`[NUI Mock] Failed to fetch NUI event ${eventName}. Returning mock data.`);
    return {} as T;
  }
}