WITH inv_wh AS (
    SELECT
        i.inv_date_sk,
        i.inv_item_sk,
        i.inv_warehouse_sk,
        i.inv_quantity_on_hand,
        w.w_warehouse_sk,
        w.w_warehouse_id,
        w.w_warehouse_name,
        w.w_city,
        w.w_state,
        w.w_gmt_offset
    FROM inventory i
    FULL OUTER JOIN warehouse w
        ON i.inv_warehouse_sk = w.w_warehouse_sk
    WHERE i.inv_quantity_on_hand IS NOT NULL OR w.w_warehouse_sk IS NOT NULL
),
filtered_inventory AS (
    SELECT *
    FROM inv_wh iwh
    WHERE iwh.inv_item_sk IN (
        SELECT ws.ws_item_sk
        FROM web_sales ws
        WHERE ws.ws_net_profit > 1000
    )
)
SELECT
    d.d_year,
    ca.ca_state,
    cd.cd_gender,
    sm.sm_type,
    ws.ws_order_number,
    ws.ws_ext_sales_price,
    ws.ws_quantity,
    fi.inv_quantity_on_hand,
    w.w_warehouse_name,
    (ws.ws_net_profit / NULLIF(ws.ws_ext_sales_price, 0)) AS profit_margin,
    RANK() OVER (PARTITION BY w.w_warehouse_name ORDER BY ws.ws_ext_sales_price DESC) AS sales_rank,
    LAG(ws.ws_ext_sales_price) OVER (PARTITION BY w.w_warehouse_name ORDER BY d.d_date_sk) AS prev_sales,
    SUM(ws.ws_ext_sales_price) OVER (
        PARTITION BY w.w_warehouse_name
        ORDER BY d.d_date_sk
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS running_sales,
    u.metric_name,
    u.metric_value
FROM filtered_inventory fi
JOIN date_dim d
    ON fi.inv_date_sk = d.d_date_sk
JOIN warehouse w
    ON fi.w_warehouse_sk = w.w_warehouse_sk
JOIN web_sales ws
    ON ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN ship_mode sm
    ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN time_dim t
    ON ws.ws_sold_time_sk = t.t_time_sk
JOIN customer_address ca
    ON ws.ws_bill_addr_sk = ca.ca_address_sk
JOIN customer_demographics cd
    ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
JOIN store_returns sr
    ON sr.sr_returned_date_sk = d.d_date_sk
-- additional joins required by the join rules (already satisfied above)
CROSS JOIN UNNEST(
    ARRAY['quantity', 'ext_sales_price'],
    ARRAY[ws.ws_quantity, ws.ws_ext_sales_price]
) AS u(metric_name, metric_value)
WHERE d.d_year = 2001
  AND ca.ca_state = 'CA'
  AND cd.cd_gender = 'M'
  AND ws.ws_net_profit > 0
  AND sm.sm_type = 'AIR'
ORDER BY running_sales DESC
LIMIT 100
