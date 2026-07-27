WITH
  agg_inventory AS (
    SELECT
      inv_warehouse_sk,
      inv_date_sk,
      SUM(inv_quantity_on_hand) AS total_qty
    FROM inventory
    GROUP BY inv_warehouse_sk, inv_date_sk
  ),
  sales_union AS (
    SELECT
      cs.cs_sold_date_sk          AS date_sk,
      cs.cs_warehouse_sk          AS warehouse_sk,
      cs.cs_ship_mode_sk          AS ship_mode_sk,
      CAST(NULL AS integer)      AS web_page_sk,
      cs.cs_ext_sales_price       AS sales_amount,
      cs.cs_net_profit            AS profit,
      cs.cs_bill_customer_sk      AS customer_sk,
      cs.cs_item_sk               AS item_sk,
      cs.cs_order_number          AS order_number
    FROM catalog_sales cs
    WHERE cs.cs_quantity > 5

    UNION ALL

    SELECT
      ws.ws_sold_date_sk,
      ws.ws_warehouse_sk,
      ws.ws_ship_mode_sk,
      ws.ws_web_page_sk,
      ws.ws_ext_sales_price,
      ws.ws_net_profit,
      ws.ws_bill_customer_sk,
      ws.ws_item_sk,
      ws.ws_order_number
    FROM web_sales ws
    WHERE ws.ws_quantity > 5

    UNION ALL

    SELECT
      ss.ss_sold_date_sk,
      CAST(NULL AS integer)      AS warehouse_sk,
      CAST(NULL AS integer)      AS ship_mode_sk,
      CAST(NULL AS integer)      AS web_page_sk,
      ss.ss_ext_sales_price,
      ss.ss_net_profit,
      ss.ss_customer_sk,
      ss.ss_item_sk,
      CAST(NULL AS integer)      AS order_number
    FROM store_sales ss
    WHERE ss.ss_quantity > 5
  )
SELECT
  d.d_year,
  w.w_warehouse_name,
  cc.cc_name,
  sm.sm_type,
  wp.wp_type,
  SUM(su.sales_amount)               AS total_sales,
  SUM(su.profit)                     AS total_profit,
  SUM(ai.total_qty)                  AS total_inventory_qty,
  COUNT(DISTINCT su.customer_sk)     AS distinct_customers,
  AVG(su.sales_amount)               AS avg_sales,
  MIN(su.sales_amount)               AS min_sales,
  MAX(su.sales_amount)               AS max_sales,
  SUM(wr.wr_return_amt)              AS total_return_amount,
  (SELECT MAX(ib_upper_bound) FROM income_band) AS max_income_upper
FROM sales_union su
JOIN date_dim d
  ON su.date_sk = d.d_date_sk
JOIN warehouse w
  ON su.warehouse_sk = w.w_warehouse_sk
LEFT JOIN agg_inventory ai
  ON ai.inv_warehouse_sk = w.w_warehouse_sk
 AND ai.inv_date_sk = d.d_date_sk
LEFT JOIN ship_mode sm
  ON su.ship_mode_sk = sm.sm_ship_mode_sk
LEFT JOIN web_page wp
  ON su.web_page_sk = wp.wp_web_page_sk
LEFT JOIN call_center cc
  ON d.d_date_sk = cc.cc_open_date_sk
LEFT JOIN customer c
  ON su.customer_sk = c.c_customer_sk
LEFT JOIN household_demographics hd
  ON c.c_current_hdemo_sk = hd.hd_demo_sk
LEFT JOIN income_band ib
  ON hd.hd_income_band_sk = ib.ib_income_band_sk
LEFT JOIN web_returns wr
  ON su.order_number = wr.wr_order_number
 AND su.item_sk = wr.wr_item_sk
WHERE d.d_year = 2002
  AND ib.ib_upper_bound >= 100000
  AND c.c_preferred_cust_flag = 'Y'
  AND EXISTS (
        SELECT 1
        FROM web_returns wr2
        WHERE wr2.wr_refunded_customer_sk = c.c_customer_sk
          AND wr2.wr_net_loss > 1000
      )
GROUP BY
  d.d_year,
  w.w_warehouse_name,
  cc.cc_name,
  sm.sm_type,
  wp.wp_type
ORDER BY total_sales DESC
LIMIT 100
