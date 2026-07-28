WITH ss_agg AS (
   SELECT
      ss.ss_item_sk,
      ss.ss_store_sk,
      ss.ss_ticket_number,
      SUM(ss.ss_ext_sales_price)        AS total_sales,
      SUM(ss.ss_net_paid)               AS total_net_paid
   FROM store_sales ss
   JOIN time_dim td_sales
        ON ss.ss_sold_time_sk = td_sales.t_time_sk
   JOIN customer_address ca_sales
        ON ss.ss_addr_sk = ca_sales.ca_address_sk
   JOIN store s_sales
        ON ss.ss_store_sk = s_sales.s_store_sk
   GROUP BY ss.ss_item_sk, ss.ss_store_sk, ss.ss_ticket_number
)
SELECT
   s_ret.s_store_name,
   r.r_reason_desc,
   td_ret.t_hour,
   SUM(ss_agg.total_sales)                     AS total_sales,
   SUM(sr.sr_return_amt)                       AS total_return_amount,
   SUM(sr.sr_fee)                               AS total_return_fee,
   SUM(cs.cs_net_paid_inc_ship)                AS total_catalog_net_paid,
   CASE
      WHEN SUM(sr.sr_store_credit) > 500 THEN 'HIGH'
      ELSE 'LOW'
   END                                         AS credit_category
FROM ss_agg
JOIN store_returns sr
   ON ss_agg.ss_item_sk      = sr.sr_item_sk
  AND ss_agg.ss_ticket_number = sr.sr_ticket_number
JOIN time_dim td_ret
   ON sr.sr_return_time_sk = td_ret.t_time_sk
JOIN customer_address ca_ret
   ON sr.sr_addr_sk = ca_ret.ca_address_sk
JOIN store s_ret
   ON sr.sr_store_sk = s_ret.s_store_sk
JOIN reason r
   ON sr.sr_reason_sk = r.r_reason_sk
-- Join catalog_sales using allowed dimension keys
JOIN catalog_sales cs
   ON cs.cs_sold_time_sk = td_ret.t_time_sk           -- same time_dim alias, allowed rule
JOIN customer_address ca_bill
   ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
JOIN customer_address ca_ship
   ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
JOIN warehouse w
   ON cs.cs_warehouse_sk = w.w_warehouse_sk
GROUP BY s_ret.s_store_name, r.r_reason_desc, td_ret.t_hour
ORDER BY total_sales DESC
