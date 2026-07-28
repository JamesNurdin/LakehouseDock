WITH base AS (
    SELECT
        cs.cs_sold_date_sk,
        sm.sm_type,
        cs.cs_ext_sales_price,
        cs.cs_net_profit
    FROM catalog_sales cs
    JOIN ship_mode sm
      ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE cs.cs_list_price > 100
      AND cs.cs_quantity BETWEEN 1 AND 5
      AND cs.cs_wholesale_cost < 150
      AND cs.cs_coupon_amt > 50
      AND cs.cs_ship_mode_sk IS NOT NULL
      AND sm.sm_code = 'AIR'
      AND EXISTS (
          SELECT 1 FROM ship_mode sm2
          WHERE sm2.sm_ship_mode_sk = cs.cs_ship_mode_sk
            AND sm2.sm_contract = 'Xjy3ZPuiDjzHlRx14Z3'
      )
), agg1 AS (
    SELECT
        sm_type,
        cs_sold_date_sk,
        SUM(cs_ext_sales_price) AS total_sales,
        SUM(cs_net_profit) AS total_profit,
        COUNT(*) AS order_cnt
    FROM base
    GROUP BY ROLLUP(sm_type, cs_sold_date_sk)
), ranked AS (
    SELECT
        sm_type,
        cs_sold_date_sk,
        total_sales,
        total_profit,
        order_cnt,
        ROW_NUMBER() OVER (PARTITION BY sm_type ORDER BY total_sales DESC) AS sales_rank
    FROM agg1
    WHERE sm_type IS NOT NULL AND cs_sold_date_sk IS NOT NULL
), final AS (
    SELECT
        sm_type,
        AVG(total_sales) AS avg_sales,
        SUM(total_profit) AS sum_profit,
        COUNT(*) AS date_cnt,
        MAX(sales_rank) AS max_rank
    FROM ranked
    GROUP BY sm_type
    HAVING AVG(total_sales) > (
        SELECT AVG(total_sales) FROM agg1 WHERE sm_type IS NOT NULL
    )
)
SELECT
    sm_type,
    avg_sales,
    sum_profit,
    date_cnt,
    max_rank
FROM final
ORDER BY avg_sales DESC
LIMIT 100
