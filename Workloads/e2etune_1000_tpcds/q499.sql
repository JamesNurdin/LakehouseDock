WITH sales_by_group AS (
    SELECT
        cc.cc_state AS state,
        sm.sm_type AS ship_mode,
        cp.cp_department AS department,
        COUNT(DISTINCT cs.cs_order_number) AS num_orders,
        SUM(cs.cs_net_profit) AS total_net_profit,
        AVG(cs.cs_quantity) AS avg_quantity,
        SUM(cs.cs_ext_discount_amt) AS total_discount,
        SUM(cs.cs_ext_tax) AS total_tax
    FROM catalog_sales cs
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE cc.cc_state IN ('TN', 'LA', 'GA')
      AND cp.cp_type = 'catalog'
      AND sm.sm_type = 'AIR'
      AND cs.cs_sold_date_sk BETWEEN 2450806 AND 2451024
    GROUP BY cc.cc_state, sm.sm_type, cp.cp_department
    HAVING SUM(cs.cs_net_profit) > 10000
)
SELECT
    state,
    ship_mode,
    department,
    num_orders,
    total_net_profit,
    avg_quantity,
    total_discount,
    total_tax,
    total_net_profit / SUM(total_net_profit) OVER () AS profit_share
FROM sales_by_group
ORDER BY total_net_profit DESC
LIMIT 50
