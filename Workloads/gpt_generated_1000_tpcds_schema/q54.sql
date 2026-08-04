/* Goal: Identify top customers in 2001 who purchased both in‑store and online, showing their sales quantities, returns, gender, inventory on hand for the items bought, and compute running and lagged net paid amounts. */
WITH
  /* Aggregate inventory per item and warehouse */
  agg_inventory AS (
    SELECT
      inv_item_sk,
      inv_warehouse_sk,
      SUM(inv_quantity_on_hand) AS total_on_hand
    FROM inventory
    GROUP BY inv_item_sk, inv_warehouse_sk
  ),
  /* Customers that appear in both store_sales and web_sales */
  intersect_customers AS (
    SELECT ss_customer_sk AS c_customer_sk
    FROM store_sales
    INTERSECT
    SELECT ws_bill_customer_sk
    FROM web_sales
  ),
  /* Core aggregation per customer per day */
  sales_agg AS (
    SELECT
      c.c_customer_sk,
      c.c_customer_id,
      d_store.d_date,
      CASE WHEN cd.cd_gender = 'M' THEN 'Male' ELSE 'Female' END AS gender,
      SUM(ss.ss_quantity)                AS store_quantity,
      SUM(ss.ss_net_paid)                AS store_net_paid,
      SUM(ws.ws_quantity)                AS web_quantity,
      SUM(ws.ws_net_paid)                AS web_net_paid,
      SUM(cs.cs_net_profit)              AS total_net_profit,
      SUM(cr.cr_return_quantity)         AS return_quantity,
      agg_inv.total_on_hand
    FROM intersect_customers ic
    JOIN customer c                     ON ic.c_customer_sk = c.c_customer_sk
    JOIN store_sales ss                 ON c.c_customer_sk = ss.ss_customer_sk
    JOIN date_dim d_store               ON ss.ss_sold_date_sk = d_store.d_date_sk
    JOIN time_dim t_store               ON ss.ss_sold_time_sk = t_store.t_time_sk
    JOIN item i1                        ON ss.ss_item_sk = i1.i_item_sk
    JOIN customer_demographics cd      ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca           ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN agg_inventory agg_inv         ON i1.i_item_sk = agg_inv.inv_item_sk
    JOIN catalog_sales cs              ON c.c_customer_sk = cs.cs_bill_customer_sk
    JOIN catalog_returns cr            ON cs.cs_order_number = cr.cr_order_number
    JOIN web_sales ws                  ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN call_center cc                ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp               ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm                  ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w                   ON cs.cs_warehouse_sk = w.w_warehouse_sk
    /* Additional date/time joins for completeness */
    JOIN date_dim d_cs                  ON cs.cs_sold_date_sk = d_cs.d_date_sk
    JOIN time_dim t_cs                  ON cs.cs_sold_time_sk = t_cs.t_time_sk
    JOIN date_dim d_ws                  ON ws.ws_sold_date_sk = d_ws.d_date_sk
    JOIN time_dim t_ws                  ON ws.ws_sold_time_sk = t_ws.t_time_sk
    WHERE d_store.d_year = 2001
    GROUP BY
      c.c_customer_sk,
      c.c_customer_id,
      d_store.d_date,
      cd.cd_gender,
      agg_inv.total_on_hand
  )
SELECT
  c_customer_id,
  d_date,
  gender,
  store_quantity,
  web_quantity,
  return_quantity,
  total_on_hand,
  store_net_paid,
  web_net_paid,
  total_net_profit,
  LAG(store_net_paid) OVER (PARTITION BY c_customer_id ORDER BY d_date) AS prev_store_net_paid,
  SUM(store_net_paid) OVER (PARTITION BY c_customer_id ORDER BY d_date ROWS UNBOUNDED PRECEDING) AS running_store_net_paid
FROM sales_agg
ORDER BY d_date DESC
LIMIT 100
