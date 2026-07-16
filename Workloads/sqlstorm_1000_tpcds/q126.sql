WITH sales_agg AS (
    SELECT
        d.d_year,
        i.i_category,
        s.s_state,
        SUM(ss.ss_net_profit) AS total_profit,
        COUNT(*) AS transaction_count,
        AVG(ss.ss_quantity) AS avg_quantity
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk AND p.p_discount_active = 'Y'
    WHERE d.d_year BETWEEN 2000 AND 2002
      AND s.s_state IN ('CA', 'TX', 'NY')
    GROUP BY d.d_year, i.i_category, s.s_state
)
SELECT
    d_year,
    i_category,
    s_state,
    total_profit,
    transaction_count,
    avg_quantity,
    ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY total_profit DESC) AS profit_rank,
    SUM(total_profit) OVER (PARTITION BY d_year ORDER BY i_category ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_profit_by_category
FROM sales_agg
ORDER BY d_year, profit_rank
LIMIT 100
