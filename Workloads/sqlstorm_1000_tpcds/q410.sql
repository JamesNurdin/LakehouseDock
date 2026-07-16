WITH aggregated AS (
    SELECT
        d.d_year,
        s.s_store_name,
        i.i_category,
        SUM(ss.ss_net_paid) AS total_net_paid,
        SUM(ss.ss_net_profit) AS total_net_profit,
        AVG(ss.ss_quantity) AS avg_quantity
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
      AND s.s_state = 'TX'
      AND i.i_brand = 'Brand#12'
    GROUP BY d.d_year, s.s_store_name, i.i_category
    HAVING SUM(ss.ss_net_profit) > 0
)
SELECT
    d_year,
    s_store_name,
    i_category,
    total_net_paid,
    total_net_profit,
    avg_quantity,
    ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY total_net_profit DESC) AS rank_by_profit,
    SUM(total_net_profit) OVER (PARTITION BY d_year ORDER BY i_category) AS cum_profit_by_category
FROM aggregated
ORDER BY d_year, total_net_profit DESC
LIMIT 100
