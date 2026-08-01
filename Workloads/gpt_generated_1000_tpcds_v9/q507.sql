WITH sales_agg AS (
    SELECT
        cc.cc_call_center_sk,
        cc.cc_name,
        w.w_warehouse_sk,
        w.w_state,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_net_profit) AS total_profit,
        SUM(cs.cs_quantity) AS total_quantity,
        CASE 
            WHEN SUM(cs.cs_net_profit) > 0 THEN 'Profit'
            ELSE 'Loss'
        END AS profit_flag
    FROM catalog_sales cs
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN inventory i ON w.w_warehouse_sk = i.inv_warehouse_sk
    WHERE cc.cc_employees > 500000
      AND w.w_gmt_offset = -5.00
      AND cs.cs_quantity > 0
      AND i.inv_quantity_on_hand > 5
      AND cs.cs_net_paid_inc_tax > 500.00
    GROUP BY cc.cc_call_center_sk, cc.cc_name, w.w_warehouse_sk, w.w_state
)
SELECT
    profit_flag,
    w_state,
    SUM(total_sales) AS sum_total_sales,
    AVG(total_profit) AS avg_total_profit,
    COUNT(*) AS num_groups,
    CASE 
        WHEN SUM(total_sales) > (SELECT AVG(total_sales) FROM sales_agg) THEN 'Above Overall Avg'
        ELSE 'Below Overall Avg'
    END AS sales_vs_overall_avg
FROM sales_agg
GROUP BY ROLLUP (profit_flag, w_state)
HAVING SUM(total_sales) > 10000
ORDER BY sum_total_sales DESC
LIMIT 100
