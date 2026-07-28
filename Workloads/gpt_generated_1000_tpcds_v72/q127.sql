WITH sales_agg AS (
    SELECT
        sm.sm_type,
        cs.cs_item_sk,
        COUNT(*) AS sales_cnt,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_net_profit) AS total_profit,
        CASE
            WHEN SUM(cs.cs_net_profit) > 0 THEN 'PROFIT'
            ELSE 'LOSS'
        END AS profit_flag
    FROM catalog_sales cs
    CROSS JOIN LATERAL (
        SELECT sm_type, sm_ship_mode_sk
        FROM ship_mode sm
        WHERE sm.sm_ship_mode_sk = cs.cs_ship_mode_sk
    ) sm
    WHERE cs.cs_ext_wholesale_cost > 500
      AND cs.cs_quantity >= 2
      AND cs.cs_net_paid_inc_tax < 5000
    GROUP BY ROLLUP (sm.sm_type, cs.cs_item_sk)
)
SELECT
    CASE WHEN GROUPING(sm_type) = 0 THEN sm_type ELSE 'ALL_TYPES' END AS sm_type,
    CASE WHEN GROUPING(profit_flag) = 0 THEN profit_flag ELSE 'ALL_FLAGS' END AS profit_flag,
    SUM(sales_cnt) AS total_sales_cnt,
    SUM(total_sales) AS total_sales_amount,
    SUM(total_profit) AS total_profit_amount,
    SUM(ret_cnt) AS total_ret_cnt,
    SUM(total_ret_amount) AS total_ret_amount,
    AVG(overall_avg_profit) AS avg_overall_profit
FROM (
    SELECT
        sa.sm_type,
        sa.profit_flag,
        sa.sales_cnt,
        sa.total_sales,
        sa.total_profit,
        COALESCE(r.ret_cnt, 0) AS ret_cnt,
        COALESCE(r.total_ret_amount, 0) AS total_ret_amount,
        (SELECT AVG(cs2.cs_net_profit) FROM catalog_sales cs2) AS overall_avg_profit
    FROM sales_agg sa
    LEFT JOIN (
        SELECT
            cr.cr_item_sk,
            COUNT(*) AS ret_cnt,
            SUM(cr.cr_return_amount) AS total_ret_amount
        FROM catalog_returns cr
        WHERE cr.cr_return_ship_cost > 200
          AND cr.cr_refunded_customer_sk IN (3338735, 7036683, 8666501)
          AND cr.cr_return_quantity >= 1
        GROUP BY cr.cr_item_sk
    ) r
      ON r.cr_item_sk = sa.cs_item_sk
) t
GROUP BY GROUPING SETS ((sm_type, profit_flag), (sm_type), (profit_flag), ())
ORDER BY sm_type, profit_flag
LIMIT 100
