WITH base AS (
   SELECT
      i.i_item_id,
      i.i_product_name,
      cc.cc_state,
      cp.cp_type,
      hd_refunded.hd_income_band_sk,
      cr.cr_return_amount,
      cr.cr_net_loss,
      ws.ws_quantity,
      ws.ws_net_paid,
      ws.ws_net_profit,
      ws.ws_sold_date_sk
   FROM catalog_returns cr
   JOIN item i ON cr.cr_item_sk = i.i_item_sk
   JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
   JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
   JOIN warehouse w_cr ON cr.cr_warehouse_sk = w_cr.w_warehouse_sk
   JOIN customer c_refunded ON cr.cr_refunded_customer_sk = c_refunded.c_customer_sk
   JOIN household_demographics hd_refunded ON cr.cr_refunded_hdemo_sk = hd_refunded.hd_demo_sk
   JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
   JOIN warehouse w_ws ON ws.ws_warehouse_sk = w_ws.w_warehouse_sk
   JOIN customer c_bill ON ws.ws_bill_customer_sk = c_bill.c_customer_sk
   JOIN household_demographics hd_bill ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
   JOIN web_site ws_site ON ws.ws_web_site_sk = ws_site.web_site_sk
   WHERE cp.cp_type = 'monthly'
     AND i.i_current_price > 50
     AND cc.cc_state = 'CA'
),

per_item AS (
   SELECT
      i_item_id,
      sum(cr_return_amount) AS total_return_amount,
      sum(cr_net_loss) AS total_net_loss,
      sum(ws_net_paid) AS total_sales,
      sum(ws_net_profit) AS total_profit,
      count(*) AS trans_cnt
   FROM base
   GROUP BY i_item_id
   HAVING sum(ws_net_paid) > 1000
),

items_with_returns AS (
   SELECT i_item_id FROM per_item WHERE total_return_amount > 0
),

items_with_high_sales AS (
   SELECT i_item_id FROM per_item WHERE total_sales > 5000
),

intersect_items AS (
   SELECT i_item_id FROM items_with_returns
   INTERSECT
   SELECT i_item_id FROM items_with_high_sales
)

SELECT
   substr(i_item_id, 1, 1) AS item_prefix,
   avg(total_return_amount) AS avg_return_amount,
   avg(total_profit) AS avg_profit,
   sum(total_sales) AS sum_sales,
   count(*) AS num_items
FROM per_item
WHERE i_item_id IN (SELECT i_item_id FROM intersect_items)
  AND total_net_loss < 0
GROUP BY substr(i_item_id, 1, 1)
HAVING count(*) > 5
ORDER BY avg_return_amount DESC
LIMIT 100
