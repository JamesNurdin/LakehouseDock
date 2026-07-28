WITH avg_profit AS (
    SELECT AVG(ss2.ss_net_profit) AS avg_net_profit
    FROM store_sales ss2
)
SELECT
    s.s_store_id,
    s.s_store_name,
    CONCAT(s.s_city, ', ', s.s_state) AS store_location,
    SUM(ss.ss_net_profit) AS total_net_profit,
    COUNT(DISTINCT ss.ss_ticket_number) AS distinct_sales,
    CASE
        WHEN SUM(ss.ss_net_profit) > (SELECT avg_net_profit FROM avg_profit) THEN 'Above Avg'
        ELSE 'Below Avg'
    END AS profit_category
FROM store_sales ss
JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
JOIN time_dim t
    ON ss.ss_sold_time_sk = t.t_time_sk
LEFT JOIN store_returns sr
    ON ss.ss_ticket_number = sr.sr_ticket_number
   AND ss.ss_store_sk = sr.sr_store_sk
LEFT JOIN reason r
    ON sr.sr_reason_sk = r.r_reason_sk
WHERE
    t.t_sub_shift = 'morning'
    AND regexp_like(r.r_reason_desc, '(?i)color')
    AND s.s_city LIKE 'A%'
    AND EXISTS (
        SELECT 1
        FROM store_returns sr2
        JOIN reason r2 ON sr2.sr_reason_sk = r2.r_reason_sk
        WHERE sr2.sr_store_sk = s.s_store_sk
          AND regexp_like(r2.r_reason_desc, '(?i)delay')
    )
GROUP BY
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    s.s_state
ORDER BY total_net_profit DESC
LIMIT 100
