SELECT
    d.d_year,
    r.r_reason_desc,
    SUBSTRING(wp.wp_web_page_id, 1, 8) AS page_prefix,
    REGEXP_EXTRACT(wp.wp_web_page_id, '([A-Z]{5})$') AS page_suffix,
    CASE
        WHEN r.r_reason_desc LIKE '%damage%' THEN 'Damage'
        WHEN r.r_reason_desc LIKE '%defect%' THEN 'Defect'
        ELSE 'Other'
    END AS reason_category,
    SUM(wr.wr_net_loss) AS total_net_loss,
    COUNT(*) AS return_count,
    CASE
        WHEN SUM(wr.wr_net_loss) > 1000 THEN 'HighLoss'
        ELSE 'LowLoss'
    END AS loss_category,
    CONCAT(CAST(d.d_year AS VARCHAR), '-', SUBSTRING(wp.wp_web_page_id, 1, 8)) AS year_page_key
FROM web_returns wr
JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
WHERE wp.wp_web_page_id LIKE 'AAAAAAA%'
  AND REGEXP_LIKE(r.r_reason_desc, '(?i)damage|defect')
GROUP BY
    d.d_year,
    r.r_reason_desc,
    SUBSTRING(wp.wp_web_page_id, 1, 8),
    REGEXP_EXTRACT(wp.wp_web_page_id, '([A-Z]{5})$'),
    CASE
        WHEN r.r_reason_desc LIKE '%damage%' THEN 'Damage'
        WHEN r.r_reason_desc LIKE '%defect%' THEN 'Defect'
        ELSE 'Other'
    END,
    CONCAT(CAST(d.d_year AS VARCHAR), '-', SUBSTRING(wp.wp_web_page_id, 1, 8))
ORDER BY total_net_loss DESC
LIMIT 100
