SELECT
    s.s_store_name,
    d.d_year,
    SUM(cr.cr_net_loss) AS total_net_loss,
    COUNT(*) AS return_cnt,
    regexp_extract(s.s_store_name, '(\\w+)$', 1) AS store_last_word,
    concat(s.s_city, ', ', s.s_state) AS store_location
FROM tpcds.catalog_returns cr
JOIN tpcds.date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
JOIN tpcds.store s ON s.s_closed_date_sk = d.d_date_sk
JOIN tpcds.household_demographics hd_ref ON cr.cr_refunded_hdemo_sk = hd_ref.hd_demo_sk
WHERE regexp_like(s.s_store_name, '(?i)^(bar|pri)')
  AND s.s_suite_number LIKE 'Suite %'
  AND EXISTS (
        SELECT 1
        FROM tpcds.web_site ws
        WHERE ws.web_open_date_sk = d.d_date_sk
          AND ws.web_street_type LIKE 'Drive'
          AND ws.web_state = s.s_state
    )
GROUP BY s.s_store_name, d.d_year, s.s_city, s.s_state
HAVING SUM(cr.cr_net_loss) > 1000
ORDER BY total_net_loss DESC
LIMIT 100
