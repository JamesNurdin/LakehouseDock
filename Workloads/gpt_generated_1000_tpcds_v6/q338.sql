WITH sales_agg AS (
    SELECT
        cp.cp_department AS department,
        sm.sm_carrier AS carrier,
        CASE WHEN cs.cs_net_profit > 1000 THEN 'High' ELSE 'Low' END AS profit_category,
        SUM(cs.cs_net_profit) AS profit_sum,
        SUM(cs.cs_quantity) AS quantity_sum,
        COUNT(DISTINCT cs.cs_order_number) AS order_cnt
    FROM catalog_sales cs
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE cc.cc_state = 'CA'
      AND cp.cp_department = 'DEPARTMENT'
      AND sm.sm_carrier = 'USPS'
      AND cs.cs_ship_date_sk BETWEEN 2450800 AND 2450900
      AND cs.cs_ext_list_price > 3000
      AND i.i_color = 'Red'
    GROUP BY cp.cp_department,
             sm.sm_carrier,
             CASE WHEN cs.cs_net_profit > 1000 THEN 'High' ELSE 'Low' END
),

dept_totals AS (
    SELECT
        department,
        SUM(profit_sum) AS total_profit,
        SUM(quantity_sum) AS total_quantity,
        SUM(order_cnt) AS total_orders
    FROM sales_agg
    GROUP BY department
    HAVING SUM(profit_sum) > 20000
)
SELECT
    sa.department,
    sa.carrier,
    sa.profit_category,
    sa.profit_sum,
    sa.quantity_sum,
    sa.order_cnt,
    dt.total_profit,
    dt.total_quantity,
    dt.total_orders,
    SUM(sa.profit_sum) OVER (PARTITION BY sa.department ORDER BY sa.profit_sum DESC) AS cum_profit_by_dept,
    RANK() OVER (ORDER BY dt.total_profit DESC) AS dept_rank
FROM sales_agg sa
JOIN dept_totals dt ON sa.department = dt.department
WHERE sa.profit_sum > 5000
ORDER BY dt.total_profit DESC, sa.profit_sum DESC
LIMIT 100
