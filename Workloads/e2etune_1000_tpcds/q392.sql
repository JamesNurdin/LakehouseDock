WITH daily_sales AS (
    SELECT
        ss_store_sk,
        ss_sold_date_sk,
        ss_promo_sk,
        SUM(ss_net_profit) AS daily_net_profit,
        SUM(ss_quantity) AS daily_quantity,
        COUNT(DISTINCT ss_ticket_number) AS daily_tickets
    FROM store_sales
    GROUP BY ss_store_sk, ss_sold_date_sk, ss_promo_sk
)
SELECT
    ds.ss_store_sk AS store_id,
    d.d_year,
    d.d_quarter_name AS quarter,
    p.p_promo_name,
    SUM(ds.daily_net_profit) AS total_net_profit,
    SUM(ds.daily_quantity) AS total_quantity,
    AVG(ds.daily_net_profit) AS avg_daily_profit,
    COUNT(DISTINCT ds.ss_sold_date_sk) AS active_days,
    SUM(p.p_cost) AS total_promo_cost,
    CASE WHEN SUM(p.p_cost) > 0 THEN SUM(ds.daily_net_profit) / SUM(p.p_cost) ELSE NULL END AS profit_to_cost_ratio,
    ROW_NUMBER() OVER (PARTITION BY ds.ss_store_sk ORDER BY SUM(ds.daily_net_profit) DESC) AS profit_rank
FROM daily_sales ds
JOIN date_dim d ON ds.ss_sold_date_sk = d.d_date_sk
JOIN promotion p ON ds.ss_promo_sk = p.p_promo_sk
WHERE d.d_weekend = 'N'
  AND p.p_discount_active = 'Y'
  AND d.d_fy_year = 1902
GROUP BY ds.ss_store_sk, d.d_year, d.d_quarter_name, p.p_promo_name
HAVING SUM(ds.daily_net_profit) > 0
ORDER BY total_net_profit DESC
LIMIT 50
