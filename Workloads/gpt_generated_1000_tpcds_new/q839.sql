WITH intersect_items AS (
   SELECT inv_item_sk
   FROM inventory
   WHERE inv_quantity_on_hand > 500
   INTERSECT
   SELECT sr_item_sk
   FROM store_returns
   WHERE sr_return_amt > 100
),
base AS (
   SELECT
     d.d_year,
     it.i_category,
     w.w_warehouse_name,
     MIN(d.d_date_sk)        AS min_date_sk,
     MIN(it.i_item_sk)       AS item_sk,
     SUM(ss.ss_ext_sales_price) AS sum_sales,
     SUM(sr.sr_return_amt)       AS sum_returns,
     SUM(ss.ss_net_profit)       AS sum_profit,
     SUM(i.inv_quantity_on_hand) AS sum_inventory
   FROM date_dim d
   JOIN inventory i          ON i.inv_date_sk = d.d_date_sk
   JOIN warehouse w          ON i.inv_warehouse_sk = w.w_warehouse_sk
   JOIN item it              ON i.inv_item_sk = it.i_item_sk
   JOIN store_sales ss       ON ss.ss_item_sk = it.i_item_sk
   JOIN store_returns sr     ON sr.sr_item_sk = ss.ss_item_sk
                               AND sr.sr_ticket_number = ss.ss_ticket_number
   JOIN time_dim t           ON sr.sr_return_time_sk = t.t_time_sk
   JOIN web_sales ws         ON ws.ws_sold_time_sk = t.t_time_sk
   JOIN web_returns wr       ON wr.wr_item_sk = ws.ws_item_sk
                               AND wr.wr_order_number = ws.ws_order_number
   JOIN web_page wp          ON wr.wr_web_page_sk = wp.wp_web_page_sk
   JOIN call_center cc       ON cc.cc_closed_date_sk = d.d_date_sk
   WHERE d.d_year = 2001
     AND it.i_brand_id = 123
     AND ws.ws_list_price > 50
   GROUP BY CUBE (d.d_year, it.i_category, w.w_warehouse_name)
),
filtered AS (
   SELECT b.*
   FROM base b
   JOIN intersect_items ii ON b.item_sk = ii.inv_item_sk
   WHERE b.sum_profit > 0
)
SELECT
  f.d_year,
  f.i_category,
  f.w_warehouse_name,
  f.sum_sales,
  f.sum_returns,
  f.sum_profit,
  f.sum_inventory,
  CASE WHEN f.sum_sales > 0 THEN f.sum_profit / f.sum_sales ELSE 0 END AS profit_margin,
  (SELECT COUNT(*)
   FROM web_page wp2
   WHERE wp2.wp_creation_date_sk = f.min_date_sk) AS pages_created_on_min_date
FROM filtered f
ORDER BY profit_margin DESC, f.sum_sales DESC
LIMIT 100
