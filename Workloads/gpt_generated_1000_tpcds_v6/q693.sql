WITH sales AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_sold_time_sk,
        ss.ss_store_sk,
        ss.ss_cdemo_sk,
        ss.ss_addr_sk,
        ss.ss_item_sk,
        ss.ss_ext_sales_price,
        ss.ss_net_profit
    FROM tpcds.store_sales ss
    WHERE ss.ss_ext_sales_price > 1000
),
returns AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_returned_time_sk,
        cr.cr_warehouse_sk,
        cr.cr_return_amount,
        cr.cr_net_loss,
        cr.cr_call_center_sk,
        cr.cr_refunded_cdemo_sk,
        cr.cr_refunded_addr_sk
    FROM tpcds.catalog_returns cr
    WHERE cr.cr_return_amount > 500
),
inv AS (
    SELECT
        i.inv_date_sk,
        i.inv_warehouse_sk,
        i.inv_quantity_on_hand
    FROM tpcds.inventory i
    WHERE i.inv_quantity_on_hand > 0
)
SELECT
    d_sales.d_year,
    s.s_store_name,
    cc.cc_name,
    w.w_warehouse_name,
    SUM(sales.ss_ext_sales_price)            AS total_sales,
    SUM(sales.ss_net_profit)                 AS total_profit,
    SUM(returns.cr_return_amount)            AS total_return_amount,
    SUM(returns.cr_net_loss)                 AS total_return_net_loss,
    SUM(inv.inv_quantity_on_hand)            AS total_inventory_quantity
FROM sales
-- store_sales dimension joins
JOIN tpcds.date_dim d_sales
  ON sales.ss_sold_date_sk = d_sales.d_date_sk
JOIN tpcds.time_dim t_sales
  ON sales.ss_sold_time_sk = t_sales.t_time_sk
JOIN tpcds.customer_demographics cd_sales
  ON sales.ss_cdemo_sk = cd_sales.cd_demo_sk
JOIN tpcds.customer_address ca_sales
  ON sales.ss_addr_sk = ca_sales.ca_address_sk
JOIN tpcds.store s
  ON sales.ss_store_sk = s.s_store_sk
JOIN tpcds.date_dim d_store_closed
  ON s.s_closed_date_sk = d_store_closed.d_date_sk
-- catalog_returns dimension joins
JOIN returns
  ON returns.cr_returned_date_sk = d_sales.d_date_sk
JOIN tpcds.date_dim d_return
  ON returns.cr_returned_date_sk = d_return.d_date_sk
JOIN tpcds.time_dim t_return
  ON returns.cr_returned_time_sk = t_return.t_time_sk
JOIN tpcds.customer_demographics cd_return_refunded
  ON returns.cr_refunded_cdemo_sk = cd_return_refunded.cd_demo_sk
JOIN tpcds.customer_address ca_return_refunded
  ON returns.cr_refunded_addr_sk = ca_return_refunded.ca_address_sk
JOIN tpcds.call_center cc
  ON returns.cr_call_center_sk = cc.cc_call_center_sk
JOIN tpcds.date_dim d_cc_closed
  ON cc.cc_closed_date_sk = d_cc_closed.d_date_sk
JOIN tpcds.warehouse w
  ON returns.cr_warehouse_sk = w.w_warehouse_sk
-- inventory joins (date_dim alias reused)
JOIN inv
  ON inv.inv_date_sk = d_sales.d_date_sk
  AND inv.inv_warehouse_sk = w.w_warehouse_sk
-- semi‑join to keep only stores that have at least one return for the same date & warehouse
WHERE EXISTS (
    SELECT 1
    FROM tpcds.catalog_returns cr2
    JOIN tpcds.date_dim d2
      ON cr2.cr_returned_date_sk = d2.d_date_sk
    WHERE d2.d_date_sk = d_sales.d_date_sk
      AND cr2.cr_warehouse_sk = w.w_warehouse_sk
)
  AND d_sales.d_year = 2001
GROUP BY
    d_sales.d_year,
    s.s_store_name,
    cc.cc_name,
    w.w_warehouse_name
ORDER BY
    total_sales DESC
LIMIT 100
