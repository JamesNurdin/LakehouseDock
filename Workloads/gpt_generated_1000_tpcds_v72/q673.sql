WITH sales_agg AS (
    SELECT
        s.s_store_id AS store_id,
        d.d_year AS year,
        d.d_month_seq AS month,
        'sales' AS metric_type,
        SUM(ss.ss_net_profit) AS amount,
        CONCAT(s.s_store_name, ' - ', s.s_city) AS store_full_name
    FROM store_sales ss
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    WHERE s.s_city LIKE 'San%'
      AND regexp_like(ca.ca_street_name, '(?i)oak')
    GROUP BY s.s_store_id, d.d_year, d.d_month_seq, s.s_store_name, s.s_city
)
SELECT
    store_id,
    year,
    month,
    metric_type,
    amount,
    store_full_name
FROM sales_agg
UNION ALL
SELECT
    s.s_store_id AS store_id,
    d.d_year AS year,
    d.d_month_seq AS month,
    'returns' AS metric_type,
    SUM(sr.sr_net_loss) AS amount,
    CONCAT(s.s_store_name, ' - ', s.s_city) AS store_full_name
FROM store_returns sr
JOIN store s
    ON sr.sr_store_sk = s.s_store_sk
JOIN date_dim d
    ON sr.sr_returned_date_sk = d.d_date_sk
JOIN reason r
    ON sr.sr_reason_sk = r.r_reason_sk
JOIN customer_address ca
    ON sr.sr_addr_sk = ca.ca_address_sk
WHERE s.s_city LIKE 'San%'
  AND regexp_extract(r.r_reason_desc, '(damaged|broken)', 1) IS NOT NULL
GROUP BY s.s_store_id, d.d_year, d.d_month_seq, s.s_store_name, s.s_city
ORDER BY year, month, amount DESC
LIMIT 100
