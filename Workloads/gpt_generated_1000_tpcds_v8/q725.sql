-- Goal: Identify customers who (1) are sampled from the customer base, (2) have high total sales across store and web channels, (3) did not generate any returns, and present their details ordered by customer key with pagination.
WITH
  sampled_customers AS (
    SELECT
      c_customer_sk,
      c_first_name,
      c_last_name,
      c_email_address
    FROM customer
    TABLESAMPLE BERNOULLI (10) -- approx. 10 % sample
  ),

  store_sales_agg AS (
    SELECT
      ss.ss_customer_sk AS customer_sk,
      SUM(ss.ss_ext_sales_price) AS total_store_sales,
      COUNT(*) AS store_txn_cnt
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE p.p_promo_name = 'Clearance'
    GROUP BY ss.ss_customer_sk
  ),

  web_sales_agg AS (
    SELECT
      ws.ws_bill_customer_sk AS customer_sk,
      SUM(ws.ws_ext_sales_price) AS total_web_sales,
      COUNT(*) AS web_txn_cnt
    FROM web_sales ws
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE p.p_channel_email = 'Y'
    GROUP BY ws.ws_bill_customer_sk
  ),

  full_sales AS (
    SELECT
      COALESCE(sa.customer_sk, wa.customer_sk) AS customer_sk,
      sa.total_store_sales,
      wa.total_web_sales,
      sa.store_txn_cnt,
      wa.web_txn_cnt
    FROM store_sales_agg sa
    FULL OUTER JOIN web_sales_agg wa
      ON sa.customer_sk = wa.customer_sk
  ),

  high_value_customers AS (
    SELECT
      customer_sk
    FROM full_sales
    WHERE COALESCE(total_store_sales, 0) + COALESCE(total_web_sales, 0) > 1000
  ),

  returning_customers AS (
    SELECT DISTINCT sr.sr_customer_sk AS customer_sk
    FROM store_returns sr
    UNION
    SELECT DISTINCT wr.wr_refunded_customer_sk AS customer_sk
    FROM web_returns wr
  ),

  intersected_customers AS (
    SELECT hv.customer_sk
    FROM high_value_customers hv
    INTERSECT
    SELECT sc.c_customer_sk
    FROM sampled_customers sc
  ),

  final_customers AS (
    SELECT ic.customer_sk
    FROM intersected_customers ic
    EXCEPT
    SELECT rc.customer_sk FROM returning_customers rc
  )
SELECT
  fc.customer_sk,
  c.c_first_name,
  c.c_last_name,
  c.c_email_address,
  fs.total_store_sales,
  fs.total_web_sales
FROM final_customers fc
JOIN customer c ON fc.customer_sk = c.c_customer_sk
LEFT JOIN full_sales fs ON fc.customer_sk = fs.customer_sk
ORDER BY fc.customer_sk
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
