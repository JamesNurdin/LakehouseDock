WITH base AS (
   SELECT
     s.s_store_id,
     d_sales.d_year,
     i.i_category,
     cs.cs_order_number,
     cs.cs_ext_sales_price,
     cr.cr_return_amount,
     w.w_warehouse_id,
     t.t_hour,
     hd.hd_income_band_sk,
     cc.cc_call_center_id,
     p.p_promo_name
   FROM catalog_sales cs
   JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
   JOIN date_dim d_sales ON cs.cs_sold_date_sk = d_sales.d_date_sk
   JOIN date_dim d_return ON cr.cr_returned_date_sk = d_return.d_date_sk
   JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
   JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
   JOIN item i ON cs.cs_item_sk = i.i_item_sk
   JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
   JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
   JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
   JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
   JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
   JOIN store s ON s.s_closed_date_sk = d_sales.d_date_sk
   WHERE d_sales.d_year BETWEEN 1998 AND 2000
     AND i.i_current_price > 100
     AND w.w_gmt_offset = -6.00
     AND p.p_discount_active = 'Y'
     AND cc.cc_gmt_offset BETWEEN -8.00 AND -5.00
),
agg AS (
   SELECT
     s_store_id,
     d_year,
     i_category,
     SUM(cs_ext_sales_price) AS sum_sales,
     SUM(cr_return_amount) AS sum_returns,
     COUNT(DISTINCT cs_order_number) AS orders_cnt,
     ROW_NUMBER() OVER (PARTITION BY s_store_id ORDER BY SUM(cs_ext_sales_price) DESC) AS rn
   FROM base
   GROUP BY s_store_id, d_year, i_category
   HAVING SUM(cs_ext_sales_price) > 1000
)
SELECT
  s_store_id,
  d_year,
  i_category,
  sum_sales,
  sum_returns,
  orders_cnt,
  rn,
  ROW_NUMBER() OVER (ORDER BY sum_sales DESC) AS global_rn
FROM (
   SELECT DISTINCT
     a.s_store_id,
     a.d_year,
     a.i_category,
     a.sum_sales,
     a.sum_returns,
     a.orders_cnt,
     a.rn
   FROM agg a
   WHERE EXISTS (
       SELECT 1 FROM base b
       WHERE b.s_store_id = a.s_store_id
         AND b.d_year = a.d_year
   )
   UNION
   SELECT DISTINCT
     a.s_store_id,
     a.d_year,
     a.i_category,
     a.sum_sales * 0.9 AS sum_sales,
     a.sum_returns,
     a.orders_cnt,
     a.rn
   FROM agg a
   WHERE a.rn <= 5
) u
ORDER BY d_year DESC, sum_sales DESC
LIMIT 100
