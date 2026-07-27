WITH base AS (
  SELECT
    d.d_year,
    i.i_category,
    SUM(cs.cs_ext_sales_price) AS sum_catalog_sales,
    SUM(ss.ss_ext_sales_price) AS sum_store_sales,
    SUM(wr.wr_return_amt) AS sum_web_returns,
    SUM(cr.cr_return_amount) AS sum_catalog_returns,
    COUNT(DISTINCT cs.cs_order_number) AS num_orders
  FROM catalog_sales cs
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
  JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
  JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
  JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
  JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
  JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
  LEFT JOIN catalog_returns cr
    ON cr.cr_order_number = cs.cs_order_number
   AND cr.cr_item_sk = cs.cs_item_sk
  LEFT JOIN inventory inv
    ON inv.inv_item_sk = i.i_item_sk
   AND inv.inv_date_sk = d.d_date_sk
  LEFT JOIN store_sales ss
    ON ss.ss_item_sk = i.i_item_sk
   AND ss.ss_sold_date_sk = d.d_date_sk
  LEFT JOIN web_returns wr
    ON wr.wr_item_sk = i.i_item_sk
   AND wr.wr_returned_date_sk = d.d_date_sk
  LEFT JOIN web_page wp
    ON wr.wr_web_page_sk = wp.wp_web_page_sk
  WHERE d.d_year = 2001
    AND i.i_current_price > 50
    AND w.w_state = 'CA'
    AND ib.ib_upper_bound >= 80000
    AND p.p_discount_active = 'Y'
    AND c.c_preferred_cust_flag = 'Y'
    AND hd.hd_vehicle_count >= 1
    AND EXISTS (
        SELECT 1
        FROM web_site ws
        WHERE ws.web_country = 'United States'
          AND ws.web_open_date_sk = d.d_date_sk
    )
  GROUP BY d.d_year, i.i_category
)
SELECT
  d_year,
  i_category,
  sum_catalog_sales,
  sum_store_sales,
  sum_web_returns,
  sum_catalog_returns,
  num_orders,
  (sum_catalog_sales + sum_store_sales) / NULLIF(num_orders, 0) AS avg_sales_per_order
FROM base
WHERE (sum_catalog_sales + sum_store_sales) > 100000
ORDER BY d_year DESC, sum_catalog_sales DESC
LIMIT 100
