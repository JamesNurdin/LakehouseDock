WITH cc_filtered AS (
    SELECT
        cc.cc_call_center_sk,
        cc.cc_call_center_id,
        cc.cc_state,
        cc.cc_employees,
        cc.cc_tax_percentage,
        cc.cc_closed_date_sk,
        cc.cc_open_date_sk
    FROM call_center cc
    WHERE cc.cc_state = 'CA'
      AND cc.cc_employees > 50
      AND cc.cc_street_name LIKE 'Hill%'
      AND cc.cc_tax_percentage > 0.05
),
ws_filtered AS (
    SELECT
        ws.web_site_sk,
        ws.web_site_id,
        ws.web_class,
        ws.web_country,
        ws.web_open_date_sk,
        ws.web_close_date_sk
    FROM web_site ws
    WHERE ws.web_country = 'United States'
      AND ws.web_mkt_class LIKE '%women%'
      AND ws.web_open_date_sk IS NOT NULL
      AND ws.web_close_date_sk IS NOT NULL
)
SELECT
    cc.cc_state,
    ws.web_class,
    d.d_quarter_name,
    COUNT(DISTINCT cc.cc_call_center_id) AS distinct_cc_cnt,
    SUM(cc.cc_employees) AS total_employees,
    AVG(cc.cc_tax_percentage) AS avg_tax_pct,
    MIN(d.d_dom) AS min_day_of_month,
    MAX(d.d_dom) AS max_day_of_month
FROM cc_filtered cc
JOIN date_dim d ON cc.cc_closed_date_sk = d.d_date_sk
JOIN ws_filtered ws ON ws.web_open_date_sk = d.d_date_sk
WHERE d.d_year = 2000
  AND d.d_dom IN (5, 12)
  AND d.d_first_dom = 2415052
  AND EXISTS (
        SELECT 1
        FROM call_center cc2
        WHERE cc2.cc_employees > (SELECT AVG(cc3.cc_employees) FROM call_center cc3)
          AND cc2.cc_state = cc.cc_state
    )
GROUP BY cc.cc_state, ws.web_class, d.d_quarter_name
HAVING COUNT(DISTINCT cc.cc_call_center_id) > 5
   AND SUM(cc.cc_employees) > 1000
ORDER BY total_employees DESC
LIMIT 100
