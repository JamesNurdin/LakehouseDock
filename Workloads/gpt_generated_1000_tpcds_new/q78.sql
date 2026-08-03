WITH sampled_inventory AS (
   SELECT *
   FROM inventory
   TABLESAMPLE BERNOULLI (10)
),
base AS (
   SELECT
       d.d_year,
       d.d_month_seq,
       c.c_customer_id,
       hd.hd_income_band_sk AS hd_income_band_sk,
       ib.ib_lower_bound,
       ib.ib_upper_bound,
       cp.cp_department,
       s.s_store_name,
       ws.web_name,
       cs.cs_ext_sales_price,
       cr.cr_return_amount,
       sr.sr_return_amt,
       cs.cs_item_sk
   FROM date_dim d
   JOIN catalog_sales cs
     ON cs.cs_sold_date_sk = d.d_date_sk
   JOIN catalog_page cp
     ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
   JOIN catalog_returns cr
     ON cr.cr_order_number = cs.cs_order_number
     AND cr.cr_item_sk = cs.cs_item_sk
   JOIN store_returns sr
     ON sr.sr_returned_date_sk = d.d_date_sk
   JOIN store s
     ON s.s_closed_date_sk = d.d_date_sk
   JOIN web_site ws
     ON ws.web_open_date_sk = d.d_date_sk
   JOIN customer c
     ON cs.cs_bill_customer_sk = c.c_customer_sk
   JOIN household_demographics hd
     ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
   JOIN income_band ib
     ON hd.hd_income_band_sk = ib.ib_income_band_sk
   JOIN sampled_inventory inv
     ON inv.inv_date_sk = d.d_date_sk
   WHERE
       d.d_year = 2001
       AND d.d_month_seq BETWEEN 1 AND 12
       AND cp.cp_department = 'Home'
       AND c.c_preferred_cust_flag = 'Y'
       AND s.s_state = 'CA'
       AND ws.web_class = 'A'
)
SELECT
   d_year,
   d_month_seq,
   c_customer_id,
   hd_income_band_sk,
   ib_lower_bound,
   ib_upper_bound,
   cp_department,
   s_store_name,
   web_name,
   SUM(cs_ext_sales_price) AS total_sales,
   SUM(cr_return_amount) AS total_returns,
   SUM(sr_return_amt) AS total_store_returns,
   COUNT(DISTINCT cs_item_sk) AS distinct_items_sold,
   MIN(cs_ext_sales_price) AS min_sales_price,
   MAX(cs_ext_sales_price) AS max_sales_price,
   ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY SUM(cs_ext_sales_price) DESC) AS rn
FROM base
GROUP BY
   d_year,
   d_month_seq,
   c_customer_id,
   hd_income_band_sk,
   ib_lower_bound,
   ib_upper_bound,
   cp_department,
   s_store_name,
   web_name
ORDER BY total_sales DESC
LIMIT 100
