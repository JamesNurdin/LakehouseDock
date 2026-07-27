WITH sales_by_time AS (
    SELECT
        ss.ss_promo_sk AS promo_sk,
        td.t_hour,
        td.t_am_pm,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        AVG(ss.ss_net_profit) AS avg_profit,
        COUNT(DISTINCT ss.ss_ticket_number) AS unique_tickets
    FROM store_sales ss
    JOIN time_dim td
        ON ss.ss_sold_time_sk = td.t_time_sk
    WHERE td.t_hour IN (9, 17, 18, 5)               -- selective hour filter
      AND td.t_am_pm = 'PM'                         -- AM/PM filter
      AND ss.ss_wholesale_cost > 50                -- cost filter
      AND ss.ss_ext_discount_amt < 5000            -- discount filter
    GROUP BY ss.ss_promo_sk, td.t_hour, td.t_am_pm
)
SELECT
    p.p_promo_id,
    sbt.t_hour,
    sbt.t_am_pm,
    sbt.total_sales,
    sbt.avg_profit,
    sbt.unique_tickets,
    CASE
        WHEN sbt.avg_profit > 100 THEN 'HIGH'
        WHEN sbt.avg_profit BETWEEN 0 AND 100 THEN 'MEDIUM'
        ELSE 'LOW'
    END AS profit_category,
    COUNT(DISTINCT sbt.t_hour) OVER (PARTITION BY p.p_promo_id) AS distinct_hours_per_promo
FROM sales_by_time sbt
JOIN promotion p
    ON sbt.promo_sk = p.p_promo_sk
WHERE EXISTS (
    SELECT 1
    FROM promotion p2
    WHERE p2.p_promo_sk = sbt.promo_sk
      AND p2.p_channel_event = 'N'
      AND p2.p_channel_catalog = 'N'
)
ORDER BY sbt.total_sales DESC
LIMIT 100
