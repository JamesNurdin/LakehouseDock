WITH merged_data AS (
   SELECT
     d1.d_year,
     i.i_category,
     i.i_brand,
     cc.cc_name,
     cp.cp_catalog_page_id,
     p.p_promo_name,
     ws.ws_order_number,
     ws.ws_net_paid,
     wr.wr_net_loss,
     cr.cr_return_amount,
     cr.cr_net_loss
   FROM web_sales ws
   JOIN date_dim d1
     ON ws.ws_sold_date_sk = d1.d_date_sk
   JOIN time_dim t1
     ON ws.ws_sold_time_sk = t1.t_time_sk
   JOIN item i
     ON ws.ws_item_sk = i.i_item_sk
   JOIN customer c_bill
     ON ws.ws_bill_customer_sk = c_bill.c_customer_sk
   JOIN household_demographics hd_bill
     ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
   JOIN customer_address ca_bill
     ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
   JOIN promotion p
     ON ws.ws_promo_sk = p.p_promo_sk
   JOIN call_center cc
     ON cc.cc_closed_date_sk = d1.d_date_sk
   JOIN catalog_page cp
     ON cp.cp_end_date_sk = d1.d_date_sk
   LEFT JOIN web_returns wr
     ON wr.wr_order_number = ws.ws_order_number
   LEFT JOIN catalog_returns cr
     ON cr.cr_order_number = ws.ws_order_number
   WHERE d1.d_year = 2001
     AND i.i_category = 'Sports'
     AND cc.cc_state = 'CA'
     AND p.p_discount_active = 'Y'
     AND t1.t_hour BETWEEN 9 AND 17
),
agg_data AS (
   SELECT
     d_year,
     i_category,
     SUM(ws_net_paid) AS total_sales,
     SUM(COALESCE(wr_net_loss, 0)) AS total_return_loss,
     SUM(COALESCE(cr_return_amount, 0)) AS total_catalog_return
   FROM merged_data
   GROUP BY CUBE (d_year, i_category)
   HAVING SUM(ws_net_paid) > 10000
)
SELECT
  d_year,
  i_category,
  total_sales,
  total_return_loss,
  total_catalog_return,
  ROW_NUMBER() OVER (PARTITION BY i_category ORDER BY total_sales DESC) AS sales_rank,
  AVG(total_sales) OVER () AS avg_sales_overall
FROM agg_data
ORDER BY total_sales DESC
LIMIT 100
