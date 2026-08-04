WITH sales_sample AS (
   SELECT *
   FROM catalog_sales
   TABLESAMPLE BERNOULLI (10)
),
sales_agg AS (
   SELECT
      cs_order_number,
      cs_item_sk,
      cs_warehouse_sk,
      cs_promo_sk,
      cs_sold_time_sk,
      SUM(cs_quantity) AS total_qty,
      SUM(cs_net_profit) AS total_profit
   FROM sales_sample
   GROUP BY cs_order_number, cs_item_sk, cs_warehouse_sk, cs_promo_sk, cs_sold_time_sk
),
orders_without_returns AS (
   SELECT cs_order_number
   FROM sales_agg
   EXCEPT
   SELECT cr_order_number
   FROM catalog_returns
)
SELECT
   sa.cs_order_number,
   i.i_item_id,
   i.i_product_name,
   w.w_warehouse_name,
   p.p_promo_name,
   t_sold.t_hour,
   sa.total_qty,
   sa.total_profit,
   CASE WHEN sa.total_profit > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_category,
   cust_ref.c_first_name || ' ' || cust_ref.c_last_name AS refunded_customer_name,
   cust_ret.c_first_name || ' ' || cust_ret.c_last_name AS returning_customer_name,
   ws.ws_quantity AS web_quantity,
   ws.ws_net_paid AS web_net_paid
FROM orders_without_returns owr
JOIN sales_agg sa ON owr.cs_order_number = sa.cs_order_number
JOIN item i ON sa.cs_item_sk = i.i_item_sk
JOIN warehouse w ON sa.cs_warehouse_sk = w.w_warehouse_sk
JOIN promotion p ON sa.cs_promo_sk = p.p_promo_sk
JOIN time_dim t_sold ON sa.cs_sold_time_sk = t_sold.t_time_sk
LEFT JOIN catalog_returns cr ON cr.cr_order_number = sa.cs_order_number
LEFT JOIN customer cust_ref ON cr.cr_refunded_customer_sk = cust_ref.c_customer_sk
LEFT JOIN household_demographics hd_ref ON cr.cr_refunded_hdemo_sk = hd_ref.hd_demo_sk
LEFT JOIN customer cust_ret ON cr.cr_returning_customer_sk = cust_ret.c_customer_sk
LEFT JOIN household_demographics hd_ret ON cr.cr_returning_hdemo_sk = hd_ret.hd_demo_sk
JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
   AND ws.ws_warehouse_sk = w.w_warehouse_sk
   AND ws.ws_promo_sk = p.p_promo_sk
JOIN time_dim t_ws ON ws.ws_sold_time_sk = t_ws.t_time_sk
JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN web_site site ON ws.ws_web_site_sk = site.web_site_sk
WHERE NOT EXISTS (
   SELECT 1
   FROM catalog_returns cr2
   WHERE cr2.cr_order_number = sa.cs_order_number
     AND cr2.cr_return_quantity > 0
)
LIMIT 100
