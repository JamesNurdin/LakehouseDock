WITH joined_data AS (
    SELECT
        ws.ws_order_number            AS order_number,
        ws.ws_sold_date_sk            AS sold_date_sk,
        ws.ws_quantity                AS quantity,
        ws.ws_wholesale_cost          AS wholesale_cost,
        ws.ws_net_paid_inc_tax        AS net_paid_inc_tax,
        sm.sm_type                    AS ship_type,
        sm.sm_carrier                 AS ship_carrier,
        wh.w_city                     AS warehouse_city,
        wh.w_warehouse_name           AS warehouse_name,
        r.r_reason_desc               AS reason_desc,
        wr.wr_return_quantity         AS return_quantity,
        wr.wr_return_amt              AS return_amt,
        wr.wr_return_tax              AS return_tax,
        wr.wr_reversed_charge         AS reversed_charge,
        CASE WHEN wr.wr_reversed_charge > 100 THEN 'High' ELSE 'Low' END AS charge_flag
    FROM web_sales ws
    JOIN ship_mode sm
        ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse wh
        ON ws.ws_warehouse_sk = wh.w_warehouse_sk
    JOIN web_returns wr
        ON wr.wr_order_number = ws.ws_order_number
       AND wr.wr_item_sk = ws.ws_item_sk
    JOIN reason r
        ON wr.wr_reason_sk = r.r_reason_sk
    WHERE ws.ws_wholesale_cost > 50
      AND ws.ws_net_paid_inc_tax < 3000
      AND wr.wr_return_tax BETWEEN 20 AND 150
      AND wh.w_city IN ('Liberty', 'Salem')
)
SELECT
    order_number,
    sold_date_sk,
    quantity,
    wholesale_cost,
    net_paid_inc_tax,
    ship_type,
    ship_carrier,
    warehouse_city,
    warehouse_name,
    reason_desc,
    return_quantity,
    return_amt,
    return_tax,
    reversed_charge,
    charge_flag,
    ROW_NUMBER() OVER (PARTITION BY warehouse_city ORDER BY net_paid_inc_tax DESC) AS city_rank,
    SUM(return_amt) OVER (PARTITION BY warehouse_city ORDER BY net_paid_inc_tax
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_return_amt
FROM joined_data
ORDER BY city_rank
LIMIT 100
