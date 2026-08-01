WITH store_ret AS (
    SELECT
        r.r_reason_desc AS reason_desc,
        sr.sr_net_loss AS net_loss,
        s.s_store_name AS store_name,
        s.s_city AS store_city,
        sr.sr_returned_date_sk AS returned_date_sk
    FROM store_returns sr
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
    WHERE s.s_city LIKE 'Washington%'
      AND regexp_like(r.r_reason_desc, '(?i)customer')
),
catalog_ret AS (
    SELECT
        r.r_reason_desc AS reason_desc,
        cr.cr_net_loss AS net_loss,
        CAST(NULL AS varchar) AS store_name,
        ca.ca_city AS store_city,
        cr.cr_returned_date_sk AS returned_date_sk
    FROM catalog_returns cr
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
    WHERE ca.ca_city LIKE 'Washington%'
      AND regexp_like(r.r_reason_desc, '(?i)customer')
),
combined_returns AS (
    SELECT * FROM store_ret
    UNION ALL
    SELECT * FROM catalog_ret
)
SELECT
    cr.reason_desc,
    SUM(cr.net_loss) AS total_net_loss,
    COUNT(*) AS total_returns,
    substring(cr.reason_desc, 1, 3) AS reason_prefix,
    CONCAT(COALESCE(cr.store_name, ''), ' (', COALESCE(cr.store_city, ''), ')') AS store_info,
    regexp_extract(cr.reason_desc, '(\\w+)', 1) AS first_word,
    (SELECT COUNT(*)
     FROM store_returns sr2
     JOIN reason r2 ON sr2.sr_reason_sk = r2.r_reason_sk
     JOIN store s2 ON sr2.sr_store_sk = s2.s_store_sk
     WHERE r2.r_reason_desc = cr.reason_desc
       AND s2.s_city = cr.store_city) AS city_reason_store_return_count
FROM combined_returns cr
GROUP BY
    cr.reason_desc,
    cr.store_name,
    cr.store_city,
    substring(cr.reason_desc, 1, 3),
    regexp_extract(cr.reason_desc, '(\\w+)', 1)
ORDER BY total_net_loss DESC
LIMIT 100
