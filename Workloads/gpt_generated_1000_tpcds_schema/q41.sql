WITH filtered_customers AS (
       SELECT c_customer_sk
       FROM customer
       WHERE c_preferred_cust_flag = 'Y'
   ),
   intersect_cust AS (
       SELECT cr_returning_customer_sk AS cust_sk FROM catalog_returns
       INTERSECT
       SELECT ws_bill_customer_sk FROM web_sales
   ),
   joined_data AS (
       SELECT
           s.s_store_name,
           c.c_customer_id,
           hd1.hd_buy_potential,
           ib.ib_lower_bound,
           ib.ib_upper_bound,
           sm.sm_type,
           w.w_warehouse_name,
           ss.ss_quantity,
           ss.ss_ext_sales_price,
           cr.cr_return_amount,
           ws.ws_ext_sales_price,
           wp.wp_type,
           ROW_NUMBER() OVER (PARTITION BY s.s_store_name ORDER BY ss.ss_ext_sales_price DESC) AS sales_rank
       FROM store_sales ss
       JOIN store s
         ON ss.ss_store_sk = s.s_store_sk
       JOIN customer c
         ON ss.ss_customer_sk = c.c_customer_sk
       JOIN household_demographics hd1
         ON ss.ss_hdemo_sk = hd1.hd_demo_sk
       JOIN income_band ib
         ON hd1.hd_income_band_sk = ib.ib_income_band_sk
       JOIN catalog_returns cr
         ON c.c_customer_sk = cr.cr_returning_customer_sk
       JOIN ship_mode sm
         ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
       JOIN warehouse w
         ON cr.cr_warehouse_sk = w.w_warehouse_sk
       JOIN web_sales ws
         ON c.c_customer_sk = ws.ws_bill_customer_sk
       JOIN household_demographics hd2
         ON ws.ws_bill_hdemo_sk = hd2.hd_demo_sk
       JOIN web_page wp
         ON ws.ws_web_page_sk = wp.wp_web_page_sk
       WHERE ss.ss_customer_sk IN (SELECT c_customer_sk FROM filtered_customers)
         AND c.c_customer_sk IN (SELECT cust_sk FROM intersect_cust)
   )
SELECT
    s_store_name,
    c_customer_id,
    hd_buy_potential,
    ib_lower_bound,
    ib_upper_bound,
    sm_type,
    w_warehouse_name,
    SUM(ss_ext_sales_price) AS total_store_sales,
    SUM(cr_return_amount) AS total_return_amount,
    SUM(ws_ext_sales_price) AS total_web_sales,
    COUNT(*) AS transaction_count,
    sales_rank
FROM joined_data
GROUP BY ROLLUP (s_store_name, c_customer_id, hd_buy_potential, ib_lower_bound, ib_upper_bound, sm_type, w_warehouse_name, sales_rank)
HAVING SUM(ss_ext_sales_price) > 1000
ORDER BY total_store_sales DESC
LIMIT 100
