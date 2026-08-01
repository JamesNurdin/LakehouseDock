WITH store_return_cte AS (
    SELECT
        sr.sr_ticket_number,
        sr.sr_return_quantity,
        sr.sr_net_loss,
        sr.sr_return_time_sk,
        sr.sr_store_sk,
        sr.sr_reason_sk,
        sr.sr_addr_sk,
        sr.sr_cdemo_sk
    FROM store_returns sr
)
SELECT
    s.s_store_name,
    s.s_city,
    r.r_reason_desc,
    regexp_extract(s.s_city, '([A-Za-z]+)', 1) AS city_first_word,
    SUM(sr_cte.sr_net_loss) AS total_net_loss,
    COUNT(*) AS return_count,
    CONCAT(s.s_store_name, ' - ', r.r_reason_desc) AS store_reason_label
FROM store_return_cte sr_cte
JOIN store s ON sr_cte.sr_store_sk = s.s_store_sk
JOIN reason r ON sr_cte.sr_reason_sk = r.r_reason_sk
JOIN customer_address ca ON sr_cte.sr_addr_sk = ca.ca_address_sk
JOIN time_dim td ON sr_cte.sr_return_time_sk = td.t_time_sk
WHERE
    regexp_like(s.s_store_name, '^Store[0-9]{2,}')
    AND regexp_like(r.r_reason_desc, '(?i)damage')
    AND s.s_city LIKE 'New%'
    AND td.t_hour BETWEEN 8 AND 18
    AND NOT EXISTS (
        SELECT 1
        FROM catalog_returns cr
        WHERE cr.cr_refunded_addr_sk = ca.ca_address_sk
    )
GROUP BY
    s.s_store_name,
    s.s_city,
    r.r_reason_desc,
    regexp_extract(s.s_city, '([A-Za-z]+)', 1),
    CONCAT(s.s_store_name, ' - ', r.r_reason_desc)
ORDER BY total_net_loss DESC
LIMIT 100
