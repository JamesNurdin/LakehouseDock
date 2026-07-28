WITH filtered_returns AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_returned_time_sk,
        cr.cr_call_center_sk,
        cr.cr_catalog_page_sk,
        cr.cr_ship_mode_sk,
        cr.cr_reason_sk,
        cr.cr_return_amount,
        cr.cr_return_tax,
        cr.cr_net_loss,
        cr.cr_return_quantity,
        cr.cr_order_number
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE d.d_year = 2002
      AND d.d_month_seq BETWEEN 100 AND 110
      AND t.t_hour BETWEEN 9 AND 11
      AND t.t_minute = 10
      AND r.r_reason_desc LIKE '%time%'
      AND cr.cr_return_amount > 0
)
SELECT
    c.cc_call_center_id,
    d.d_date,
    s.sm_type,
    CASE WHEN fr.cr_return_amount > 1000 THEN 'Large' ELSE 'Small' END AS return_size,
    COUNT(*) AS returns_cnt,
    SUM(fr.cr_return_amount) AS total_return_amount,
    AVG(fr.cr_return_tax) AS avg_return_tax,
    MAX(fr.cr_net_loss) AS max_net_loss,
    ROW_NUMBER() OVER (PARTITION BY c.cc_call_center_id ORDER BY SUM(fr.cr_return_amount) DESC) AS rn
FROM filtered_returns fr
JOIN call_center c ON fr.cr_call_center_sk = c.cc_call_center_sk
JOIN date_dim d ON fr.cr_returned_date_sk = d.d_date_sk
LEFT JOIN ship_mode s ON fr.cr_ship_mode_sk = s.sm_ship_mode_sk
JOIN catalog_page p ON fr.cr_catalog_page_sk = p.cp_catalog_page_sk
JOIN reason r ON fr.cr_reason_sk = r.r_reason_sk
WHERE c.cc_state = 'CA'
  AND (s.sm_type = 'OVERNIGHT' OR s.sm_type IS NULL)
GROUP BY
    c.cc_call_center_id,
    d.d_date,
    s.sm_type,
    CASE WHEN fr.cr_return_amount > 1000 THEN 'Large' ELSE 'Small' END
HAVING SUM(fr.cr_return_amount) > 500
ORDER BY total_return_amount DESC
LIMIT 100
