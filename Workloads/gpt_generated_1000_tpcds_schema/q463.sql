WITH
  cp_dates AS (
    SELECT
      cp.cp_catalog_page_id,
      cp.cp_department,
      d.d_date_sk AS date_sk,
      d.d_date
    FROM catalog_page cp
    JOIN date_dim d ON cp.cp_start_date_sk = d.d_date_sk
  ),
  ws_dates AS (
    SELECT
      ws.ws_order_number,
      ws.ws_sales_price,
      d.d_date_sk AS date_sk,
      d.d_date,
      site.web_site_id
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN web_site site ON ws.ws_web_site_sk = site.web_site_sk
  ),
  full_cp_ws AS (
    SELECT
      COALESCE(cp.cp_catalog_page_id, CAST('N/A' AS varchar)) AS catalog_page_id,
      COALESCE(ws.ws_order_number, -1) AS order_number,
      cp.cp_department,
      ws.ws_sales_price,
      cp.date_sk
    FROM cp_dates cp
    FULL OUTER JOIN ws_dates ws ON cp.date_sk = ws.date_sk
  ),

  web_sales_customers AS (
    SELECT DISTINCT c.c_customer_id
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE ws.ws_quantity > 5
      AND ws.ws_sales_price > 100
      AND d.d_year = 2001
      AND ws.ws_coupon_amt = 0.00
  ),
  store_sales_customers AS (
    SELECT DISTINCT c.c_customer_id
    FROM store_sales ss
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE ss.ss_quantity > 5
      AND ss.ss_sales_price > 100
      AND d.d_year = 2001
      AND ss.ss_ext_discount_amt > 0
  ),
  intersect_customers AS (
    SELECT c_customer_id FROM web_sales_customers
    INTERSECT
    SELECT c_customer_id FROM store_sales_customers
  ),
  catalog_return_customers AS (
    SELECT DISTINCT c.c_customer_id
    FROM catalog_returns cr
    JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    WHERE cr.cr_return_amount > 0
      AND d.d_year = 2001
      AND cr.cr_return_quantity > 0
      AND cr.cr_fee > 0
  ),
  except_customers AS (
    SELECT c_customer_id FROM catalog_return_customers
    EXCEPT
    SELECT c_customer_id FROM web_sales_customers
  ),

  final_agg AS (
    SELECT
      d.d_date,
      d.d_date_sk,
      c.c_customer_id,
      c.c_first_name,
      c.c_last_name,
      COALESCE(SUM(ss.ss_ext_sales_price), 0) AS store_sales_amt,
      COALESCE(SUM(ws.ws_ext_sales_price), 0) AS web_sales_amt,
      COALESCE(SUM(cr.cr_return_amount), 0) AS return_amt,
      CASE
        WHEN COALESCE(SUM(ss.ss_ext_sales_price), 0) + COALESCE(SUM(ws.ws_ext_sales_price), 0) - COALESCE(SUM(cr.cr_return_amount), 0) > 50000 THEN 'HIGH'
        ELSE 'NORMAL'
      END AS customer_segment
    FROM date_dim d
    LEFT JOIN store_sales ss ON ss.ss_sold_date_sk = d.d_date_sk
    LEFT JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
    LEFT JOIN catalog_returns cr ON cr.cr_returned_date_sk = d.d_date_sk
    LEFT JOIN customer c ON c.c_customer_sk = COALESCE(ss.ss_customer_sk, ws.ws_bill_customer_sk, cr.cr_refunded_customer_sk)
    LEFT JOIN household_demographics hd ON hd.hd_demo_sk = COALESCE(ss.ss_hdemo_sk, ws.ws_bill_hdemo_sk, cr.cr_refunded_hdemo_sk)
    LEFT JOIN customer_address ca ON ca.ca_address_sk = COALESCE(ss.ss_addr_sk, ws.ws_bill_addr_sk, cr.cr_refunded_addr_sk)
    LEFT JOIN promotion p ON p.p_promo_sk = COALESCE(ss.ss_promo_sk, ws.ws_promo_sk)
    LEFT JOIN warehouse w ON w.w_warehouse_sk = ws.ws_warehouse_sk
    LEFT JOIN call_center cc ON cc.cc_closed_date_sk = d.d_date_sk
    LEFT JOIN catalog_page cp ON cp.cp_start_date_sk = d.d_date_sk
    LEFT JOIN web_site site ON site.web_open_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND (ss.ss_quantity > 0 OR ws.ws_quantity > 0 OR cr.cr_return_quantity > 0)
    GROUP BY d.d_date, d.d_date_sk, c.c_customer_id, c.c_first_name, c.c_last_name
  )
SELECT DISTINCT
  f.d_date,
  f.c_customer_id,
  f.c_first_name,
  f.c_last_name,
  f.store_sales_amt,
  f.web_sales_amt,
  f.return_amt,
  f.customer_segment,
  RANK() OVER (ORDER BY (f.store_sales_amt + f.web_sales_amt - f.return_amt) DESC) AS sales_rank,
  CASE WHEN f.c_customer_id IN (SELECT c_customer_id FROM intersect_customers) THEN 'Both Channels' ELSE 'Single Channel' END AS channel_flag,
  CASE WHEN f.c_customer_id IN (SELECT c_customer_id FROM except_customers) THEN 'Return Only' ELSE NULL END AS return_only_flag,
  fc.catalog_page_id,
  fc.order_number,
  fc.ws_sales_price
FROM final_agg f
LEFT JOIN full_cp_ws fc ON fc.date_sk = f.d_date_sk
ORDER BY sales_rank ASC, f.c_customer_id
LIMIT 100
