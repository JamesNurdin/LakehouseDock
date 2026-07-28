WITH inv_agg AS (
    SELECT
        inv_warehouse_sk,
        SUM(inv_quantity_on_hand) AS total_qty_on_hand
    FROM inventory
    WHERE inv_quantity_on_hand > 0
      AND inv_date_sk BETWEEN 2451000 AND 2453000
    GROUP BY inv_warehouse_sk
)
SELECT
    w.w_warehouse_id,
    w.w_city,
    w.w_state,
    COUNT(DISTINCT c.c_customer_id) AS distinct_customers,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    SUM(ws.ws_net_profit) AS total_profit,
    ia.total_qty_on_hand,
    AVG(ws.ws_net_paid_inc_ship_tax) AS avg_net_paid_inc_ship_tax
FROM web_sales ws
JOIN customer c
    ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN household_demographics hd
    ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
JOIN warehouse w
    ON ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN inv_agg ia
    ON w.w_warehouse_sk = ia.inv_warehouse_sk
WHERE w.w_street_number = '176'
  AND w.w_street_type = 'Rd'
  AND hd.hd_income_band_sk IN (1, 2, 6)
  AND hd.hd_buy_potential = '5001-10000'
  AND ws.ws_ship_date_sk BETWEEN 2451900 AND 2452400
  AND ws.ws_net_paid_inc_ship_tax > 500
GROUP BY
    w.w_warehouse_id,
    w.w_city,
    w.w_state,
    ia.total_qty_on_hand
HAVING SUM(ws.ws_ext_sales_price) > 10000
ORDER BY total_profit DESC
LIMIT 100
