WITH
  cr AS (
    SELECT cr_returned_time_sk, cr_refunded_customer_sk, cr_return_amount, cr_net_loss
    FROM catalog_returns TABLESAMPLE BERNOULLI (10)
    WHERE cr_return_amount > 0
  ),
  sr AS (
    SELECT sr_return_time_sk, sr_customer_sk, sr_return_amt, sr_net_loss, sr_store_sk
    FROM store_returns
    WHERE sr_store_sk IN (325, 182)
  ),
  ws AS (
    SELECT ws_sold_time_sk, ws_bill_customer_sk, ws_promo_sk, ws_ext_sales_price, ws_net_profit
    FROM web_sales
    WHERE ws_ext_sales_price > 0
  ),
  cust AS (
    SELECT c_customer_sk, c_birth_month, c_preferred_cust_flag
    FROM customer
    WHERE c_birth_month IN (10, 11, 9)
  ),
  promo AS (
    SELECT p_promo_sk, p_start_date_sk, p_end_date_sk, p_discount_active
    FROM promotion
    WHERE p_discount_active = 'Y'
  ),
  tm AS (
    SELECT t_time_sk, t_meal_time, t_am_pm
    FROM time_dim
    WHERE t_meal_time IN ('lunch', 'dinner')
  ),
  return_customers AS (
    SELECT cr_refunded_customer_sk AS cust_sk FROM cr
    UNION
    SELECT sr_customer_sk FROM sr
  ),
  web_customers AS (
    SELECT ws_bill_customer_sk AS cust_sk FROM ws
    UNION
    SELECT ws_bill_customer_sk FROM ws
  ),
  new_customers AS (
    SELECT cust_sk FROM web_customers
    EXCEPT
    SELECT cust_sk FROM return_customers
  ),
  joined_data AS (
    SELECT
      CASE
        WHEN c.c_birth_month = 10 THEN 'Oct'
        WHEN c.c_birth_month = 11 THEN 'Nov'
        ELSE 'Other'
      END AS birth_month_category,
      t.t_meal_time,
      c.c_customer_sk,
      ws.ws_ext_sales_price,
      ws.ws_net_profit,
      p.p_discount_active
    FROM ws
    JOIN promo p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN cust c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN tm t ON ws.ws_sold_time_sk = t.t_time_sk
    LEFT JOIN cr cr1 ON ws.ws_sold_time_sk = cr1.cr_returned_time_sk
    LEFT JOIN sr sr1 ON ws.ws_sold_time_sk = sr1.sr_return_time_sk
    LEFT JOIN cr cr2 ON ws.ws_sold_time_sk = cr2.cr_returned_time_sk
    LEFT JOIN sr sr2 ON ws.ws_sold_time_sk = sr2.sr_return_time_sk
    LEFT JOIN cr cr3 ON ws.ws_sold_time_sk = cr3.cr_returned_time_sk
    CROSS JOIN (SELECT 1 AS dummy UNION ALL SELECT 2) AS cross_tbl
    WHERE c.c_customer_sk IN (SELECT cust_sk FROM new_customers)
  )
SELECT
  birth_month_category,
  t_meal_time,
  COUNT(DISTINCT c_customer_sk) AS num_customers,
  SUM(ws_ext_sales_price) AS total_sales,
  AVG(ws_net_profit) AS avg_profit,
  SUM(CASE WHEN p_discount_active = 'Y' THEN ws_ext_sales_price ELSE 0 END) AS discounted_sales
FROM joined_data
GROUP BY GROUPING SETS (
  (birth_month_category, t_meal_time),
  (birth_month_category),
  ()
)
UNION DISTINCT
SELECT
  'All' AS birth_month_category,
  'All' AS t_meal_time,
  COUNT(DISTINCT c_customer_sk),
  SUM(ws_ext_sales_price),
  AVG(ws_net_profit),
  SUM(CASE WHEN p_discount_active = 'Y' THEN ws_ext_sales_price ELSE 0 END)
FROM joined_data
LIMIT 100
