WITH distinct_items AS (
   SELECT DISTINCT i_item_sk
   FROM item
   WHERE i_manufact_id IN (214, 52)
),
ss_agg AS (
   SELECT
       ss_item_sk,
       ss_sold_date_sk,
       SUM(ss_ext_sales_price) AS store_sales_total,
       SUM(ss_quantity) AS store_quantity,
       COUNT(DISTINCT ss_ticket_number) AS distinct_tickets
   FROM store_sales
   WHERE ss_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2001)
     AND ss_quantity > 0
   GROUP BY ss_item_sk, ss_sold_date_sk
)
SELECT
   d.d_year,
   i.i_item_id,
   i.i_brand,
   p.p_promo_name,
   cp.cp_department,
   w.w_warehouse_name,
   ss_agg.store_sales_total,
   SUM(cr.cr_return_amount) AS total_catalog_return_amount,
   SUM(sr.sr_return_amt) AS total_store_return_amount,
   SUM(wr.wr_return_amt) AS total_web_return_amount,
   COUNT(DISTINCT cs.cs_order_number) AS distinct_catalog_orders,
   ss_agg.distinct_tickets AS distinct_store_tickets,
   AVG(cs.cs_ext_discount_amt) AS avg_catalog_discount
FROM ss_agg
JOIN store_sales ss
  ON ss.ss_item_sk = ss_agg.ss_item_sk
 AND ss.ss_sold_date_sk = ss_agg.ss_sold_date_sk
JOIN date_dim d
  ON d.d_date_sk = ss.ss_sold_date_sk
JOIN time_dim t
  ON t.t_time_sk = ss.ss_sold_time_sk
JOIN item i
  ON i.i_item_sk = ss.ss_item_sk
JOIN distinct_items di
  ON di.i_item_sk = i.i_item_sk
JOIN promotion p
  ON p.p_promo_sk = ss.ss_promo_sk
JOIN catalog_sales cs
  ON cs.cs_item_sk = i.i_item_sk
 AND cs.cs_sold_date_sk = d.d_date_sk
JOIN warehouse w
  ON w.w_warehouse_sk = cs.cs_warehouse_sk
JOIN catalog_page cp
  ON cp.cp_catalog_page_sk = cs.cs_catalog_page_sk
JOIN catalog_returns cr
  ON cr.cr_item_sk = cs.cs_item_sk
 AND cr.cr_order_number = cs.cs_order_number
JOIN reason r_cr
  ON r_cr.r_reason_sk = cr.cr_reason_sk
JOIN store_returns sr
  ON sr.sr_item_sk = ss.ss_item_sk
 AND sr.sr_ticket_number = ss.ss_ticket_number
JOIN reason r_sr
  ON r_sr.r_reason_sk = sr.sr_reason_sk
JOIN web_returns wr
  ON wr.wr_item_sk = i.i_item_sk
 AND wr.wr_returned_date_sk = d.d_date_sk
JOIN web_page wp
  ON wp.wp_web_page_sk = wr.wr_web_page_sk
JOIN reason r_wr
  ON r_wr.r_reason_sk = wr.wr_reason_sk
JOIN customer_address ca_bill
  ON ca_bill.ca_address_sk = cs.cs_bill_addr_sk
JOIN customer_address ca_ship
  ON ca_ship.ca_address_sk = cs.cs_ship_addr_sk
JOIN customer_address ca_cr_refund
  ON ca_cr_refund.ca_address_sk = cr.cr_refunded_addr_sk
JOIN customer_address ca_cr_return
  ON ca_cr_return.ca_address_sk = cr.cr_returning_addr_sk
JOIN customer_address ca_sr
  ON ca_sr.ca_address_sk = sr.sr_addr_sk
JOIN customer_address ca_wr_refund
  ON ca_wr_refund.ca_address_sk = wr.wr_refunded_addr_sk
JOIN customer_address ca_wr_return
  ON ca_wr_return.ca_address_sk = wr.wr_returning_addr_sk
WHERE
   d.d_year = 2001
   AND i.i_manufact_id IN (214, 52)
   AND p.p_discount_active = 'Y'
   AND cp.cp_department = 'Electronics'
   AND r_cr.r_reason_desc = 'Customer not satisfied'
   AND ca_bill.ca_state = 'CA'
   AND w.w_state = 'TX'
   AND t.t_hour BETWEEN 9 AND 17
GROUP BY
   d.d_year,
   i.i_item_id,
   i.i_brand,
   p.p_promo_name,
   cp.cp_department,
   w.w_warehouse_name,
   ss_agg.store_sales_total,
   ss_agg.distinct_tickets
LIMIT 100
