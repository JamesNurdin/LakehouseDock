WITH inventory_agg AS (
    SELECT
        inv_warehouse_sk,
        SUM(inv_quantity_on_hand) AS total_quantity_on_hand
    FROM inventory
    GROUP BY inv_warehouse_sk
),
web_sales_agg AS (
    SELECT
        ws_warehouse_sk,
        SUM(ws.ws_net_paid_inc_ship_tax) AS total_ws_net_paid_inc_ship_tax,
        COUNT(DISTINCT ws.ws_order_number) AS ws_order_count
    FROM web_sales ws
    GROUP BY ws_warehouse_sk
),
sales_agg AS (
    SELECT
        cc.cc_name,
        w.w_warehouse_name,
        r.r_reason_desc,
        SUM(cs.cs_net_paid_inc_ship_tax) AS total_sales_net_paid_inc_ship_tax,
        SUM(COALESCE(cr.cr_return_amount, 0)) AS total_return_amount,
        AVG(cs.cs_quantity) AS avg_sales_quantity,
        COUNT(DISTINCT cs.cs_order_number) AS distinct_order_cnt,
        COALESCE(i.total_quantity_on_hand, 0) AS total_inventory_qty,
        COALESCE(ws_agg.total_ws_net_paid_inc_ship_tax, 0) AS total_web_sales_net_paid,
        COALESCE(ws_agg.ws_order_count, 0) AS total_web_sales_orders,
        (
            SELECT MAX(r2.r_reason_sk)
            FROM reason r2
            WHERE r2.r_reason_desc = 'Found a better price in a store'
        ) AS max_reason_sk_found_price
    FROM catalog_sales cs
    JOIN customer c_bill ON cs.cs_bill_customer_sk = c_bill.c_customer_sk
    JOIN customer_demographics cd_bill ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
    LEFT JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    LEFT JOIN inventory_agg i ON i.inv_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN web_sales_agg ws_agg ON ws_agg.ws_warehouse_sk = w.w_warehouse_sk
    WHERE cc.cc_state = 'CA'
      AND w.w_state = 'CA'
      AND (r.r_reason_desc = 'Did not like the model' OR r.r_reason_desc IS NULL)
      AND cs.cs_net_paid_inc_ship_tax > 500
    GROUP BY
        cc.cc_name,
        w.w_warehouse_name,
        r.r_reason_desc,
        i.total_quantity_on_hand,
        ws_agg.total_ws_net_paid_inc_ship_tax,
        ws_agg.ws_order_count
)
SELECT
    *,
    RANK() OVER (ORDER BY total_sales_net_paid_inc_ship_tax DESC) AS sales_rank,
    SUM(total_sales_net_paid_inc_ship_tax) OVER (PARTITION BY cc_name) AS total_sales_by_center
FROM sales_agg
ORDER BY total_sales_net_paid_inc_ship_tax DESC
LIMIT 100
