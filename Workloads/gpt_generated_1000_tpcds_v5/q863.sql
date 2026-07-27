WITH yearly_sales AS (
    SELECT s.s_store_id,
           s.s_store_name,
           SUM(ss.ss_net_profit) AS total_profit,
           'Year2001' AS source
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY s.s_store_id, s.s_store_name
),
promo_sales AS (
    SELECT s.s_store_id,
           s.s_store_name,
           SUM(ss.ss_net_profit) AS total_profit,
           'PromoActive2001' AS source
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN date_dim d ON p.p_start_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND p.p_discount_active = 'Y'
    GROUP BY s.s_store_id, s.s_store_name
),
avg_profit AS (
    SELECT AVG(total_profit) AS avg_total_profit
    FROM yearly_sales
)
SELECT combined.s_store_id,
       combined.s_store_name,
       combined.total_profit,
       combined.source
FROM (
    SELECT * FROM yearly_sales
    UNION ALL
    SELECT * FROM promo_sales
) AS combined
WHERE combined.total_profit > (SELECT avg_total_profit FROM avg_profit)
ORDER BY combined.total_profit DESC
LIMIT 100
