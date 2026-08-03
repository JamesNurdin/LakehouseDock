WITH sales_dates AS (
   SELECT
      ss.ss_sold_date_sk,
      ss.ss_sold_time_sk,
      ss.ss_item_sk,
      ss.ss_customer_sk,
      ss.ss_cdemo_sk,
      ss.ss_hdemo_sk,
      ss.ss_addr_sk,
      ss.ss_store_sk,
      ss.ss_promo_sk,
      ss.ss_ticket_number,
      ss.ss_quantity,
      ss.ss_wholesale_cost,
      ss.ss_list_price,
      ss.ss_sales_price,
      ss.ss_ext_discount_amt,
      ss.ss_ext_sales_price,
      ss.ss_ext_wholesale_cost,
      ss.ss_ext_list_price,
      ss.ss_ext_tax,
      ss.ss_coupon_amt,
      ss.ss_net_paid,
      ss.ss_net_paid_inc_tax,
      ss.ss_net_profit,
      d.d_date,
      d.d_year,
      d.d_month_seq,
      d.d_week_seq,
      d.d_quarter_seq
   FROM store_sales ss
   RIGHT JOIN date_dim d
     ON ss.ss_sold_date_sk = d.d_date_sk
   WHERE d.d_year = 2002
     AND ss.ss_ext_sales_price > 1000
),
returns_ship AS (
   SELECT
      cr.cr_returned_date_sk,
      cr.cr_returned_time_sk,
      cr.cr_item_sk,
      cr.cr_refunded_customer_sk,
      cr.cr_refunded_cdemo_sk,
      cr.cr_refunded_hdemo_sk,
      cr.cr_refunded_addr_sk,
      cr.cr_returning_customer_sk,
      cr.cr_returning_cdemo_sk,
      cr.cr_returning_hdemo_sk,
      cr.cr_returning_addr_sk,
      cr.cr_call_center_sk,
      cr.cr_catalog_page_sk,
      cr.cr_ship_mode_sk,
      cr.cr_warehouse_sk,
      cr.cr_reason_sk,
      cr.cr_order_number,
      cr.cr_return_quantity,
      cr.cr_return_amount,
      cr.cr_return_tax,
      cr.cr_return_amt_inc_tax,
      cr.cr_fee,
      cr.cr_return_ship_cost,
      cr.cr_refunded_cash,
      cr.cr_reversed_charge,
      cr.cr_store_credit,
      cr.cr_net_loss,
      sm.sm_ship_mode_id,
      sm.sm_type,
      sm.sm_contract
   FROM catalog_returns cr
   FULL OUTER JOIN ship_mode sm
     ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
   WHERE sm.sm_contract = 'P7FBIt8yd'
      OR cr.cr_return_quantity > 1
)
,
aggregated AS (
   SELECT
      s.s_store_name,
      sd.d_year,
      sd.d_month_seq,
      SUM(COALESCE(sd.ss_ext_sales_price, 0)) AS total_sales_amount,
      SUM(COALESCE(rs.cr_return_amount, 0)) AS total_return_amount,
      COUNT(DISTINCT sd.ss_ticket_number) AS distinct_tickets,
      CASE
         WHEN SUM(COALESCE(sd.ss_ext_sales_price, 0)) = 0 THEN 0
         ELSE SUM(COALESCE(rs.cr_return_amount, 0)) / SUM(COALESCE(sd.ss_ext_sales_price, 0))
      END AS return_to_sales_ratio,
      ROW_NUMBER() OVER (
         PARTITION BY s.s_store_name
         ORDER BY SUM(COALESCE(sd.ss_ext_sales_price, 0)) DESC
      ) AS sales_rank
   FROM sales_dates sd
   JOIN store s
     ON sd.ss_store_sk = s.s_store_sk
   LEFT JOIN returns_ship rs
     ON sd.ss_sold_date_sk = rs.cr_returned_date_sk
   JOIN customer_address ca
     ON sd.ss_addr_sk = ca.ca_address_sk
   WHERE ca.ca_country = 'United States'
     AND ca.ca_location_type = 'single family'
   GROUP BY s.s_store_name, sd.d_year, sd.d_month_seq
   HAVING SUM(COALESCE(sd.ss_ext_sales_price, 0)) > 5000
)
SELECT
   s_store_name,
   d_year,
   d_month_seq,
   total_sales_amount,
   total_return_amount,
   distinct_tickets,
   return_to_sales_ratio,
   sales_rank
FROM aggregated
WHERE sales_rank <= 3
ORDER BY s_store_name, sales_rank
