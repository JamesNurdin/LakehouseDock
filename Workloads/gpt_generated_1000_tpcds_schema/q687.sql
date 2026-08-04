WITH base AS (
  SELECT
    cs.cs_order_number,
    cs.cs_ext_sales_price,
    cs.cs_net_profit,
    cs.cs_ship_mode_sk,
    cs.cs_warehouse_sk,
    cs.cs_sold_date_sk,
    c.c_customer_sk,
    c.c_first_sales_date_sk,
    hd.hd_demo_sk,
    hd.hd_buy_potential,
    hd.hd_vehicle_count,
    sm.sm_ship_mode_id,
    w.w_warehouse_sk,
    w.w_city,
    ss.ss_ticket_number,
    ss.ss_ext_sales_price AS ss_ext_sales_price,
    ss.ss_net_paid,
    sr.sr_return_quantity,
    sr.sr_return_amt,
    ws.ws_order_number,
    ws.ws_ext_sales_price AS ws_ext_sales_price,
    ws.ws_net_paid,
    wr.wr_return_quantity,
    wr.wr_return_amt,
    inv.inv_quantity_on_hand,
    wp.wp_web_page_id,
    wp.wp_type
  FROM catalog_sales cs
  JOIN customer c
    ON cs.cs_bill_customer_sk = c.c_customer_sk
  JOIN household_demographics hd
    ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
  JOIN ship_mode sm
    ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN warehouse w
    ON cs.cs_warehouse_sk = w.w_warehouse_sk
  JOIN store_sales ss
    ON ss.ss_ticket_number = cs.cs_order_number
  JOIN store_returns sr
    ON sr.sr_ticket_number = ss.ss_ticket_number
    AND sr.sr_customer_sk = c.c_customer_sk
  JOIN web_sales ws
    ON ws.ws_order_number = cs.cs_order_number
  JOIN web_returns wr
    ON wr.wr_order_number = ws.ws_order_number
  JOIN inventory inv
    ON inv.inv_warehouse_sk = w.w_warehouse_sk
  JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
  WHERE hd.hd_vehicle_count > 0
    AND hd.hd_buy_potential = '1001-5000'
    AND inv.inv_quantity_on_hand > 300
    AND w.w_city = 'Chicago'
),
agg1 AS (
  SELECT
    c_customer_sk,
    hd_demo_sk,
    sm_ship_mode_id,
    w_city,
    COUNT(*) AS cnt_orders,
    SUM(cs_ext_sales_price) AS sum_cs_sales,
    SUM(ss_ext_sales_price) AS sum_ss_sales,
    SUM(ws_ext_sales_price) AS sum_ws_sales,
    AVG(cs_net_profit) AS avg_cs_profit
  FROM base
  GROUP BY c_customer_sk, hd_demo_sk, sm_ship_mode_id, w_city
  HAVING COUNT(*) > 5
),
order_diff AS (
  SELECT cs_order_number FROM catalog_sales
  EXCEPT
  SELECT ws_order_number FROM web_sales
),
order_common AS (
  SELECT cs_order_number FROM catalog_sales
  INTERSECT
  SELECT ws_order_number FROM web_sales
)
SELECT *
FROM (
  SELECT
    a.c_customer_sk,
    a.hd_demo_sk,
    a.sm_ship_mode_id,
    a.w_city,
    a.cnt_orders,
    a.sum_cs_sales,
    a.sum_ss_sales,
    a.sum_ws_sales,
    a.avg_cs_profit,
    lt.weighted_profit,
    (SELECT COUNT(*) FROM order_diff) AS diff_order_count,
    (SELECT COUNT(*) FROM order_common) AS common_order_count
  FROM agg1 a
  CROSS JOIN LATERAL (
    SELECT a.cnt_orders * a.avg_cs_profit AS weighted_profit
  ) lt
  WHERE a.sum_cs_sales > (SELECT MAX(cs_ext_sales_price) FROM catalog_sales) / 2
    AND a.c_customer_sk IN (
        SELECT c_customer_sk FROM customer WHERE c_preferred_cust_flag = 'Y'
    )
    AND EXISTS (
        SELECT 1 FROM store_returns sr WHERE sr.sr_customer_sk = a.c_customer_sk
    )
  ORDER BY a.sum_cs_sales DESC
  OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
) final_result
LIMIT 100
