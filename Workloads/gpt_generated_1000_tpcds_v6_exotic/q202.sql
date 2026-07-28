WITH sales_agg AS (
    SELECT
        cs.cs_sold_time_sk,
        td.t_meal_time,
        SUM(cs.cs_net_profit) AS total_profit,
        AVG(cs.cs_ext_ship_cost) AS avg_ship_cost,
        COUNT(*) AS sales_cnt
    FROM catalog_sales cs
    JOIN time_dim td
        ON cs.cs_sold_time_sk = td.t_time_sk
    WHERE cs.cs_ext_ship_cost > 500
      AND cs.cs_ext_tax < 100
      AND cs.cs_ship_date_sk IN (2450865, 2450847, 2450882)
    GROUP BY cs.cs_sold_time_sk, td.t_meal_time
    HAVING COUNT(*) >= 10
)
SELECT
    sa.t_meal_time,
    sa.total_profit,
    sa.avg_ship_cost,
    sa.sales_cnt,
    CASE
        WHEN sa.avg_ship_cost > (
            SELECT AVG(cs_inner.cs_ext_ship_cost)
            FROM catalog_sales cs_inner
            WHERE cs_inner.cs_ext_ship_cost > 500
        ) THEN 'High'
        ELSE 'Low'
    END AS ship_cost_category,
    RANK() OVER (ORDER BY sa.total_profit DESC) AS profit_rank,
    ROW_NUMBER() OVER (PARTITION BY td2.t_shift ORDER BY sa.total_profit DESC) AS rank_within_shift
FROM sales_agg sa
LEFT OUTER JOIN time_dim td2
    ON sa.cs_sold_time_sk = td2.t_time_sk
WHERE EXISTS (
    SELECT 1
    FROM catalog_sales cs_check
    WHERE cs_check.cs_sold_time_sk = sa.cs_sold_time_sk
      AND cs_check.cs_quantity > 5
)
ORDER BY profit_rank
LIMIT 100
