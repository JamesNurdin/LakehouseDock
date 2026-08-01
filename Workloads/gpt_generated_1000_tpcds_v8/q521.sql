-- Goal: Identify the top‑selling orders from catalog and store channels, classify shipping speed, rank orders within each department, exclude any orders that later appear as web returns, and return the highest 100 rows.
WITH
  /* fact – catalog sales enriched with dimensions */
  sales_data AS (
    SELECT
      cs.cs_order_number,
      cs.cs_sold_date_sk,
      cs.cs_sold_time_sk,
      cs.cs_ext_sales_price,
      cp.cp_department,
      p.p_promo_name,
      sm.sm_carrier,
      cd_bill.cd_credit_rating AS bill_credit_rating,
      hd_bill.hd_income_band_sk,
      ib.ib_lower_bound,
      ib.ib_upper_bound,
      t.t_hour,
      t.t_am_pm
    FROM catalog_sales cs
      JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
      JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
      LEFT JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
      JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
      JOIN customer_demographics cd_bill ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
      JOIN household_demographics hd_bill ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
      JOIN income_band ib ON hd_bill.hd_income_band_sk = ib.ib_income_band_sk
    WHERE cp.cp_department = 'Sports'
      AND p.p_discount_active = 'Y'
      AND t.t_hour BETWEEN 9 AND 17
      AND sm.sm_carrier = 'DHL'
      AND ib.ib_upper_bound > 80000
  ),

  /* fact – store sales, right‑joined to time to keep all time slots */
  store_data AS (
    SELECT
      ss.ss_ticket_number,
      ss.ss_sold_date_sk,
      ss.ss_sold_time_sk,
      ss.ss_ext_sales_price,
      'Store' AS cp_department,
      'N/A' AS p_promo_name,
      cd.cd_credit_rating AS cust_credit_rating,
      hd.hd_income_band_sk,
      ib2.ib_lower_bound AS hd_lower,
      ib2.ib_upper_bound AS hd_upper,
      t2.t_hour,
      t2.t_am_pm
    FROM store_sales ss
      RIGHT OUTER JOIN time_dim t2 ON ss.ss_sold_time_sk = t2.t_time_sk
      JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
      JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
      JOIN income_band ib2 ON hd.hd_income_band_sk = ib2.ib_income_band_sk
    WHERE ss.ss_quantity > 0
      AND cd.cd_gender = 'M'
      AND ib2.ib_lower_bound >= 50000
      AND t2.t_meal_time = 'Lunch'
      AND ss.ss_net_profit > 0
  ),

  /* fact – web returns with their own dimensions */
  web_data AS (
    SELECT
      wr.wr_order_number,
      wr.wr_returned_date_sk,
      wr.wr_returned_time_sk,
      wr.wr_return_amt,
      wp.wp_url,
      cd_ref.cd_credit_rating AS refunded_credit_rating,
      hd_ref.hd_income_band_sk AS refunded_income_band_sk,
      ib_ref.ib_upper_bound AS refunded_income_upper
    FROM web_returns wr
      JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
      JOIN customer_demographics cd_ref ON wr.wr_refunded_cdemo_sk = cd_ref.cd_demo_sk
      JOIN household_demographics hd_ref ON wr.wr_refunded_hdemo_sk = hd_ref.hd_demo_sk
      JOIN income_band ib_ref ON hd_ref.hd_income_band_sk = ib_ref.ib_income_band_sk
    WHERE wp.wp_autogen_flag = 'N'
      AND wp.wp_type = 'article'
      AND wr.wr_return_amt > 0
      AND cd_ref.cd_credit_rating = 'Good'
      AND ib_ref.ib_lower_bound >= 60000
  ),

  /* union of catalog and store orders */
  combined AS (
    SELECT
      s.cs_order_number               AS order_id,
      s.cs_sold_date_sk                AS date_sk,
      s.cs_ext_sales_price            AS sales_amount,
      s.cp_department                  AS department,
      s.p_promo_name                   AS promo_name,
      CASE WHEN s.sm_carrier = 'DHL' THEN 'Fast' ELSE 'Standard' END AS shipping_speed,
      ROW_NUMBER() OVER (PARTITION BY s.cp_department ORDER BY s.cs_ext_sales_price DESC) AS dept_sales_rank,
      s.t_hour,
      s.t_am_pm
    FROM sales_data s
    UNION DISTINCT
    SELECT
      sd.ss_ticket_number              AS order_id,
      sd.ss_sold_date_sk                AS date_sk,
      sd.ss_ext_sales_price            AS sales_amount,
      sd.cp_department                  AS department,
      sd.p_promo_name                   AS promo_name,
      CASE WHEN sd.t_hour BETWEEN 9 AND 12 THEN 'Morning' ELSE 'Other' END AS shipping_speed,
      ROW_NUMBER() OVER (PARTITION BY sd.cp_department ORDER BY sd.ss_ext_sales_price DESC) AS dept_sales_rank,
      sd.t_hour,
      sd.t_am_pm
    FROM store_data sd
  ),

  /* apply filters and anti‑join to drop orders that have a web return */
  filtered_combined AS (
    SELECT c.*
    FROM combined c
    WHERE c.sales_amount > 1000
      AND c.dept_sales_rank <= 5
      AND c.t_hour BETWEEN 9 AND 18
      AND c.shipping_speed IS NOT NULL
      AND c.department IS NOT NULL
      AND NOT EXISTS (
        SELECT 1 FROM web_data wd WHERE wd.wr_order_number = c.order_id
      )
  )

SELECT
  f.order_id,
  f.date_sk,
  f.sales_amount,
  f.department,
  f.promo_name,
  f.shipping_speed,
  f.dept_sales_rank,
  f.t_hour,
  f.t_am_pm,
  (SELECT COUNT(*) FROM sales_data sd2 WHERE sd2.cp_department = f.department) AS department_order_cnt
FROM filtered_combined f
EXCEPT
SELECT
  f2.order_id,
  f2.date_sk,
  f2.sales_amount,
  f2.department,
  f2.promo_name,
  f2.shipping_speed,
  f2.dept_sales_rank,
  f2.t_hour,
  f2.t_am_pm,
  0 AS department_order_cnt
FROM filtered_combined f2
WHERE f2.sales_amount < 2000
ORDER BY sales_amount DESC
OFFSET 0
LIMIT 100
