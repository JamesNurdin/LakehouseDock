WITH state_sales AS (
    SELECT s.s_state,
           i.i_category,
           d.d_year,
           SUM(ss.ss_net_profit) AS total_net_profit,
           SUM(ss.ss_net_paid) AS total_net_paid,
           COUNT(*) AS sales_count,
           AVG(ss.ss_quantity) AS avg_quantity
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE d.d_year BETWEEN 2001 AND 2002
      AND p.p_discount_active = 'Y'
    GROUP BY s.s_state, i.i_category, d.d_year
)
SELECT s_state,
       i_category,
       d_year,
       total_net_profit,
       total_net_paid,
       sales_count,
       avg_quantity
FROM (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY s_state ORDER BY total_net_profit DESC) AS rn
    FROM state_sales
) t
WHERE rn <= 10
ORDER BY s_state, total_net_profit DESC
