WITH sr_agg AS (
    SELECT
        sr_cdemo_sk,
        SUM(sr_return_amt) AS total_return_amt,
        SUM(sr_return_quantity) AS total_return_qty,
        COUNT(DISTINCT sr_ticket_number) AS distinct_tickets
    FROM store_returns
    WHERE sr_return_amt > 20.00
      AND sr_return_quantity >= 1
      AND sr_return_ship_cost < 1000.00
      AND sr_fee BETWEEN 0 AND 500
      AND sr_refunded_cash > 0
      AND sr_net_loss > 0
    GROUP BY sr_cdemo_sk
),
ws_agg AS (
    SELECT
        ws_warehouse_sk,
        ws_bill_cdemo_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws_order_number) AS distinct_orders
    FROM web_sales
    WHERE ws_quantity > 0
      AND ws_sales_price > 0
      AND ws_ext_discount_amt < 100.00
      AND ws_ext_tax > 0
      AND ws_coupon_amt >= 0
      AND ws_ship_mode_sk IN (1, 2, 3)
    GROUP BY ws_warehouse_sk, ws_bill_cdemo_sk
)
SELECT
    cd.cd_demo_sk,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    sr.total_return_amt,
    sr.total_return_qty,
    sr.distinct_tickets,
    ws.total_sales,
    ws.total_profit,
    ws.distinct_orders,
    w.w_warehouse_name,
    w.w_city,
    w.w_state,
    w.w_warehouse_sq_ft
FROM customer_demographics cd
JOIN sr_agg sr
    ON sr.sr_cdemo_sk = cd.cd_demo_sk
JOIN ws_agg ws
    ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
JOIN warehouse w
    ON ws.ws_warehouse_sk = w.w_warehouse_sk
WHERE cd.cd_dep_count >= 2
  AND cd.cd_dep_employed_count <= 5
  AND cd.cd_credit_rating IN ('A', 'B', 'C')
  AND w.w_city = 'Seattle'
  AND w.w_state = 'CA'
  AND w.w_warehouse_sq_ft > 800000
  AND w.w_warehouse_name IS NOT NULL
ORDER BY cd.cd_demo_sk
