WITH
  filtered_sales AS (
    SELECT cs.cs_order_number,
           cs.cs_item_sk,
           cs.cs_bill_customer_sk,
           cs.cs_sold_date_sk,
           cs.cs_net_profit
    FROM catalog_sales cs TABLESAMPLE BERNOULLI (10)
    WHERE cs.cs_net_profit > 0
  ),
  email_customers AS (
    SELECT c.c_customer_sk,
           c.c_email_address
    FROM customer c
    WHERE regexp_like(c.c_email_address, '^[A-Z0-9._%+-]+@example\\.com$')
  ),
  item_desc AS (
    SELECT i.i_item_sk,
           i.i_item_desc
    FROM item i
    WHERE i.i_item_desc LIKE '%steel%'
  ),
  union_customers AS (
    SELECT c_customer_sk FROM email_customers
    UNION
    SELECT cs_bill_customer_sk FROM filtered_sales
  ),
  intersect_customers AS (
    SELECT c_customer_sk FROM email_customers
    INTERSECT
    SELECT cs_bill_customer_sk FROM filtered_sales
  ),
  exclusive_customers AS (
    SELECT c_customer_sk FROM union_customers
    EXCEPT
    SELECT c_customer_sk FROM intersect_customers
  ),
  joined_data AS (
    SELECT
      ec.c_customer_sk,
      i.i_item_desc,
      cs.cs_net_profit,
      regexp_extract(c.c_email_address, '@(.*)$', 1) AS email_domain,
      substr(i.i_item_desc, 1, 20) AS short_desc,
      concat('Cust-', cast(ec.c_customer_sk AS varchar)) AS cust_key
    FROM exclusive_customers ec
    JOIN filtered_sales cs ON cs.cs_bill_customer_sk = ec.c_customer_sk
    JOIN customer c ON c.c_customer_sk = ec.c_customer_sk
    JOIN item_desc i ON i.i_item_sk = cs.cs_item_sk
    WHERE i.i_item_desc LIKE '%steel%'
  )
SELECT
  cust_key,
  email_domain,
  short_desc,
  sum(cs_net_profit) AS total_profit,
  count(*) AS sales_cnt
FROM joined_data
GROUP BY cust_key, email_domain, short_desc
ORDER BY total_profit DESC
LIMIT 100
