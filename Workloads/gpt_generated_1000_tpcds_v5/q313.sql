WITH sales_agg AS (
    SELECT
        cc.cc_call_center_id,
        sm.sm_carrier,
        w.w_warehouse_name,
        COUNT(DISTINCT cs.cs_order_number) AS order_cnt,
        SUM(cs.cs_net_profit) AS total_profit,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        AVG(cs.cs_net_profit) AS avg_profit_per_order
    FROM catalog_sales cs
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    LEFT JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN customer_address ca_bill
        ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
    WHERE cc.cc_state = 'CA'
        AND sm.sm_carrier = 'DHL'
        AND (w.w_state = 'TX' OR w.w_state IS NULL)
        AND cs.cs_sold_date_sk BETWEEN 2450000 AND 2459999
        AND ca_bill.ca_state = 'NY'
    GROUP BY cc.cc_call_center_id, sm.sm_carrier, w.w_warehouse_name
)
SELECT
    cc_call_center_id,
    sm_carrier,
    COALESCE(w_warehouse_name, 'UNKNOWN') AS warehouse_name,
    order_cnt,
    total_profit,
    total_sales,
    avg_profit_per_order,
    (total_profit / NULLIF(total_sales, 0)) AS profit_margin
FROM sales_agg
WHERE order_cnt > 10
    AND total_sales > 1000
ORDER BY profit_margin DESC, total_sales DESC
LIMIT 100
