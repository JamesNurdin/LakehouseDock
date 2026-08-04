WITH intersect_orders AS (
    SELECT cs_order_number FROM catalog_sales WHERE cs_net_profit > 0
    INTERSECT
    SELECT ws_order_number FROM web_sales WHERE ws_net_profit > 0
),
joined_data AS (
    SELECT
        cs.cs_order_number,
        cs.cs_quantity,
        cs.cs_ext_sales_price,
        cs.cs_net_profit,
        td.t_hour,
        sm.sm_carrier,
        w.w_state,
        ca_bill.ca_state AS bill_state,
        cd_bill.cd_gender,
        store.s_store_name,
        ws.ws_quantity AS web_quantity,
        wr.wr_return_quantity,
        inv.inv_quantity_on_hand,
        reason.r_reason_desc,
        lt.discount_factor
    FROM catalog_sales cs
    INNER JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    INNER JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    INNER JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    INNER JOIN customer_address ca_bill ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
    INNER JOIN customer_demographics cd_bill ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
    FULL OUTER JOIN store_sales ss ON ss.ss_sold_time_sk = td.t_time_sk
    FULL OUTER JOIN store ON ss.ss_store_sk = store.s_store_sk
    LEFT JOIN web_sales ws ON ws.ws_sold_time_sk = td.t_time_sk
        AND ws.ws_warehouse_sk = w.w_warehouse_sk
        AND ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    LEFT JOIN web_returns wr ON wr.wr_returned_time_sk = td.t_time_sk
        AND wr.wr_order_number = ws.ws_order_number
        AND wr.wr_item_sk = ws.ws_item_sk
    LEFT JOIN reason ON wr.wr_reason_sk = reason.r_reason_sk
    LEFT JOIN inventory inv ON inv.inv_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN LATERAL (
        SELECT cs.cs_ext_discount_amt / NULLIF(cs.cs_ext_sales_price, 0) AS discount_factor
    ) lt ON TRUE
    WHERE EXISTS (
        SELECT 1 FROM inventory inv_check
        WHERE inv_check.inv_warehouse_sk = w.w_warehouse_sk
          AND inv_check.inv_quantity_on_hand > 0
    )
    AND cs.cs_order_number IN (SELECT cs_order_number FROM intersect_orders)
)
SELECT
    sm_carrier,
    w_state,
    SUM(cs_ext_sales_price) AS total_sales,
    AVG(discount_factor) AS avg_discount,
    SUM(cs_quantity) AS total_quantity,
    COUNT(DISTINCT cs_order_number) AS distinct_orders
FROM joined_data
GROUP BY sm_carrier, w_state
UNION
SELECT
    sm_carrier,
    w_state,
    SUM(cs_ext_sales_price) * 1.05 AS total_sales,
    AVG(discount_factor) AS avg_discount,
    SUM(cs_quantity) AS total_quantity,
    COUNT(DISTINCT cs_order_number) AS distinct_orders
FROM joined_data
WHERE cs_quantity > 5
GROUP BY sm_carrier, w_state
LIMIT 100
