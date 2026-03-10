import { useEffect, useState } from "react";

type Caller = {
  callerNumber: string;
  calledAt: string;
  vanityTop5: string[];
};

type ApiResponse = {
  callers: Caller[];
};

type RuntimeConfig = {
  callersApiUrl?: string;
};

export function App() {
  const [callers, setCallers] = useState<Caller[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [apiUrl, setApiUrl] = useState(
    import.meta.env.VITE_CALLERS_API_URL ?? "http://localhost:3000/callers"
  );

  useEffect(() => {
    const load = async () => {
      try {
        setLoading(true);

        let resolvedApiUrl = apiUrl;
        try {
          const configResponse = await fetch("/runtime-config.json", { cache: "no-store" });
          if (configResponse.ok) {
            const runtimeConfig = (await configResponse.json()) as RuntimeConfig;
            if (runtimeConfig.callersApiUrl) {
              resolvedApiUrl = runtimeConfig.callersApiUrl;
            }
          }
        } catch {
          // Fallback to build-time env value during local development.
        }

        setApiUrl(resolvedApiUrl);
        const response = await fetch(resolvedApiUrl);
        if (!response.ok) {
          throw new Error(`Request failed with status ${response.status}`);
        }
        const data = (await response.json()) as ApiResponse;
        setCallers(data.callers ?? []);
      } catch (err) {
        setError(err instanceof Error ? err.message : "Unknown error");
      } finally {
        setLoading(false);
      }
    };

    void load();
  }, []);

  return (
    <main className="page">
      <section className="card">
        <h1>Last 5 Vanity Callers</h1>
        <p className="api">API: {apiUrl}</p>

        {loading && <p>Loading callers...</p>}
        {error && <p className="error">{error}</p>}

        {!loading && !error && callers.length === 0 && <p>No callers yet.</p>}

        {!loading && !error && callers.length > 0 && (
          <ul className="list">
            {callers.map((caller) => (
              <li key={`${caller.calledAt}-${caller.callerNumber}`} className="item">
                <div>
                  <strong>{caller.callerNumber}</strong>
                  <span>{new Date(caller.calledAt).toLocaleString()}</span>
                </div>
                <p>{caller.vanityTop5.join(" | ")}</p>
              </li>
            ))}
          </ul>
        )}
      </section>
    </main>
  );
}
