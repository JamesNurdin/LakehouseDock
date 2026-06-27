/*
  Analytical query on the `web_logs` table.
  The log line is parsed to extract the HTTP method, request path, status code, and the number of bytes returned.
  The result shows, for each method‑status pair, how many requests were made and the total bytes transferred,
  ordered by the highest request count.
*/
WITH parsed_logs AS (
    SELECT
        line,
        -- HTTP method (e.g., GET, POST)
        regexp_extract(line, '\\"([A-Z]+)\\s', 1)               AS http_method,
        -- Request path (the part after the method and before the protocol)
        regexp_extract(line, '\\"[A-Z]+\\s+([^\\s]+)', 1)   AS request_path,
        -- HTTP status code (3‑digit number after the quoted request)
        regexp_extract(line, '\\"\s+(\\d{3})\s', 1)          AS status_code,
        -- Bytes sent (number after the status code)
        regexp_extract(line, '\\"\s+\\d{3}\s+(\\d+)', 1)   AS bytes_sent
    FROM web_logs
    WHERE line IS NOT NULL
)
SELECT
    http_method,
    status_code,
    COUNT(*)                     AS request_count,
    SUM(CAST(bytes_sent AS BIGINT)) AS total_bytes_sent
FROM parsed_logs
WHERE http_method IS NOT NULL
  AND status_code IS NOT NULL
GROUP BY http_method, status_code
ORDER BY request_count DESC
LIMIT 10
