WITH qualified_websites AS (
    SELECT DISTINCT ws.ws_web_site_sk AS web_site_sk
    FROM web_sales ws
    JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
    WHERE REGEXP_LIKE(w.web_name, '.*[A-Z]{3}.*')
      AND w.web_state LIKE 'C%'
),
excluded_websites AS (
    SELECT DISTINCT ws.ws_web_site_sk AS web_site_sk
    FROM web_sales ws
    JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
    WHERE LOWER(w.web_name) LIKE '%test%'
),
target_websites AS (
    SELECT web_site_sk FROM qualified_websites
    EXCEPT
    SELECT web_site_sk FROM excluded_websites
)
SELECT 
    w.web_site_id,
    w.web_name,
    d.d_year,
    SUM(ws.ws_net_paid) AS total_net_paid,
    SUM(ws.ws_ext_sales_price) AS total_sales_price,
    COUNT(*) AS num_transactions,
    REGEXP_EXTRACT(w.web_name, '^([^\\s]+)') AS first_word
FROM target_websites tw
JOIN web_sales ws ON ws.ws_web_site_sk = tw.web_site_sk
JOIN web_site w ON w.web_site_sk = tw.web_site_sk
JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
GROUP BY w.web_site_id, w.web_name, d.d_year, REGEXP_EXTRACT(w.web_name, '^([^\\s]+)')
ORDER BY total_net_paid DESC
LIMIT 100
