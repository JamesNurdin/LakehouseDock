WITH filtered_cc AS (
    SELECT
        cc_call_center_sk,
        cc_name,
        cc_city,
        cc_state
    FROM call_center
    WHERE regexp_like(cc_name, 'Center')
      AND cc_city LIKE 'San%'
)
SELECT
    fc.cc_name,
    w.web_name,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    REGEXP_EXTRACT(w.web_name, '(\\w+)', 1) AS web_name_first_word,
    SUM(ws.ws_net_paid) AS total_net_paid,
    COUNT(DISTINCT ws.ws_order_number) AS orders_cnt
FROM filtered_cc fc
JOIN catalog_sales cs
    ON cs.cs_call_center_sk = fc.cc_call_center_sk
JOIN household_demographics hd
    ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN web_sales ws
    ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
JOIN web_site w
    ON ws.ws_web_site_sk = w.web_site_sk
WHERE ib.ib_upper_bound BETWEEN 50000 AND 200000
  AND w.web_name LIKE '%Online%'
  AND EXISTS (
        SELECT 1
        FROM web_site ws_sub
        WHERE ws_sub.web_site_sk = w.web_site_sk
          AND regexp_like(ws_sub.web_name, '^Shop')
      )
GROUP BY fc.cc_name, w.web_name, ib.ib_lower_bound, ib.ib_upper_bound, REGEXP_EXTRACT(w.web_name, '(\\w+)', 1)
ORDER BY total_net_paid DESC
LIMIT 100
