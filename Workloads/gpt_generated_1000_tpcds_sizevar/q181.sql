WITH sales_monthly AS (
   SELECT
       cs_item_sk,
       cs_sold_date_sk,
       cs_ship_mode_sk,
       cs_promo_sk,
       cs_order_number,
       SUM(cs_quantity) AS total_qty,
       SUM(cs_net_paid) AS total_net_paid
   FROM catalog_sales
   GROUP BY cs_item_sk, cs_sold_date_sk, cs_ship_mode_sk, cs_promo_sk, cs_order_number
),
returns_filtered AS (
   SELECT
       cr_order_number,
       cr_returned_date_sk,
       cr_returned_time_sk,
       cr_item_sk,
       cr_reason_sk,
       cr_ship_mode_sk,
       cr_return_quantity,
       cr_return_amount,
       cr_returning_customer_sk,
       cr_returning_addr_sk
   FROM catalog_returns
   WHERE cr_return_amount > 20
),
order_exceptions AS (
   SELECT cr_order_number
   FROM catalog_returns
   EXCEPT
   SELECT cs_order_number
   FROM catalog_sales
)
SELECT
   i.i_item_id,
   i.i_product_name,
   d_sale.d_year,
   d_sale.d_month_seq,
   sm_ship.sm_carrier,
   p.p_promo_name,
   r.r_reason_desc,
   s.s_store_name,
   SUM(sa.total_qty) AS sold_qty,
   SUM(sa.total_net_paid) AS sold_net,
   SUM(rf.cr_return_quantity) AS returned_qty,
   SUM(rf.cr_return_amount) AS returned_amount,
   (SELECT COUNT(*) FROM customer_address WHERE ca_state = 'CA') AS ca_ca_count
FROM sales_monthly sa
JOIN item i
   ON sa.cs_item_sk = i.i_item_sk
JOIN date_dim d_sale
   ON sa.cs_sold_date_sk = d_sale.d_date_sk
JOIN ship_mode sm_ship
   ON sa.cs_ship_mode_sk = sm_ship.sm_ship_mode_sk
JOIN promotion p
   ON sa.cs_promo_sk = p.p_promo_sk
JOIN catalog_returns cr
   ON sa.cs_order_number = cr.cr_order_number
JOIN returns_filtered rf
   ON cr.cr_order_number = rf.cr_order_number
JOIN reason r
   ON rf.cr_reason_sk = r.r_reason_sk
JOIN ship_mode sm_ret
   ON rf.cr_ship_mode_sk = sm_ret.sm_ship_mode_sk
JOIN date_dim d_return
   ON rf.cr_returned_date_sk = d_return.d_date_sk
JOIN time_dim t_ret
   ON rf.cr_returned_time_sk = t_ret.t_time_sk
JOIN store s
   ON s.s_closed_date_sk = d_sale.d_date_sk
WHERE EXISTS (
   SELECT 1 FROM order_exceptions oe WHERE oe.cr_order_number = rf.cr_order_number
)
GROUP BY
   i.i_item_id,
   i.i_product_name,
   d_sale.d_year,
   d_sale.d_month_seq,
   sm_ship.sm_carrier,
   p.p_promo_name,
   r.r_reason_desc,
   s.s_store_name
ORDER BY sold_net DESC
LIMIT 100
