WITH
  sales_all AS (
    SELECT ss_customer_sk AS customer_sk,
           ss_net_profit AS net_profit,
           ss_sold_date_sk AS sold_date_sk
    FROM store_sales
    UNION ALL
    SELECT cs_bill_customer_sk AS customer_sk,
           cs_net_profit AS net_profit,
           cs_sold_date_sk AS sold_date_sk
    FROM catalog_sales
    UNION ALL
    SELECT ws_bill_customer_sk AS customer_sk,
           ws_net_profit AS net_profit,
           ws_sold_date_sk AS sold_date_sk
    FROM web_sales
  ),
  returns_all AS (
    SELECT sr_customer_sk AS customer_sk,
           sr_return_amt_inc_tax AS return_amount,
           sr_returned_date_sk AS return_date_sk
    FROM store_returns
    UNION ALL
    SELECT cr_returning_customer_sk AS customer_sk,
           cr_return_amt_inc_tax AS return_amount,
           cr_returned_date_sk AS return_date_sk
    FROM catalog_returns
    UNION ALL
    SELECT wr_returning_customer_sk AS customer_sk,
           wr_return_amt_inc_tax AS return_amount,
           wr_returned_date_sk AS return_date_sk
    FROM web_returns
  ),
  customers_with_sales AS (
    SELECT DISTINCT customer_sk FROM sales_all
  ),
  customers_with_returns AS (
    SELECT DISTINCT customer_sk FROM returns_all
  ),
  customers_both AS (
    SELECT customer_sk FROM customers_with_sales
    INTERSECT
    SELECT customer_sk FROM customers_with_returns
  ),
  customer_sales AS (
    SELECT
      s.customer_sk,
      SUM(s.net_profit) AS total_net_profit,
      MAX(s.sold_date_sk) AS last_sold_date_sk,
      COUNT(*) AS sales_transactions
    FROM sales_all s
    GROUP BY s.customer_sk
  ),
  customer_returns AS (
    SELECT
      r.customer_sk,
      COUNT(*) AS total_returns,
      SUM(r.return_amount) AS total_return_amount,
      AVG(r.return_amount) AS avg_return_amount,
      MAX(r.return_date_sk) AS last_return_date_sk
    FROM returns_all r
    GROUP BY r.customer_sk
  ),
  last_dates AS (
    SELECT
      cs.customer_sk,
      d.d_date AS last_sold_date
    FROM customer_sales cs
    LEFT JOIN date_dim d ON cs.last_sold_date_sk = d.d_date_sk
  )
SELECT
  CONCAT_WS(' ', c.c_first_name, c.c_last_name) AS customer_full_name,
  LOWER(CONCAT(c.c_first_name, '.', c.c_last_name, '@example.com')) AS synthetic_email,
  COALESCE(cs.total_net_profit, 0) AS total_net_profit,
  COALESCE(cs.sales_transactions, 0) AS total_sales_transactions,
  COALESCE(cr.total_returns, 0) AS total_returns,
  COALESCE(cr.total_return_amount, 0) AS total_return_amount,
  ld.last_sold_date,
  CASE
    WHEN ld.last_sold_date >= DATE '2022-01-01' THEN 'ACTIVE'
    WHEN cs.total_net_profit IS NULL THEN 'NEVER_PURCHASED'
    ELSE 'INACTIVE'
  END AS activity_status,
  NTILE(4) OVER (ORDER BY COALESCE(cs.total_net_profit, 0) DESC) AS profit_quartile,
  RANK() OVER (ORDER BY COALESCE(cs.total_net_profit, 0) DESC) AS profit_rank,
  CASE
    WHEN COALESCE(cs.total_net_profit, 0) > 10000 AND COALESCE(cr.total_returns, 0) = 0 THEN 'HIGH_VALUE_NO_RETURNS'
    WHEN COALESCE(cs.total_net_profit, 0) > 5000 THEN 'HIGH_VALUE'
    WHEN COALESCE(cr.total_returns, 0) > 5 THEN 'FREQUENT_RETURNER'
    ELSE 'STANDARD'
  END AS customer_segment,
  (SELECT COUNT(*) FROM sales_all s2
    WHERE s2.customer_sk = c.c_customer_sk
      AND s2.sold_date_sk = cs.last_sold_date_sk) AS sales_on_last_day,
  CASE
    WHEN EXISTS (SELECT 1 FROM sales_all s3
                 WHERE s3.customer_sk = c.c_customer_sk
                   AND s3.sold_date_sk >= (SELECT MAX(d2.d_date_sk) - 365 FROM date_dim d2)) THEN 'Y'
    ELSE 'N'
  END AS recent_one_year_flag,
  SUM(COALESCE(cr.total_return_amount, 0)) OVER () AS grand_total_return_amount
FROM customer c
LEFT JOIN customer_sales cs ON c.c_customer_sk = cs.customer_sk
LEFT JOIN customer_returns cr ON c.c_customer_sk = cr.customer_sk
LEFT JOIN last_dates ld ON c.c_customer_sk = ld.customer_sk
WHERE (c.c_preferred_cust_flag = 'Y' OR c.c_preferred_cust_flag IS NULL)
  AND (c.c_customer_sk IN (SELECT customer_sk FROM customers_both) OR cs.customer_sk IS NOT NULL)
ORDER BY total_net_profit DESC NULLS LAST
LIMIT 100
