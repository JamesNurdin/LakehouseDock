WITH sampled_customers AS (
  SELECT c.c_customer_sk,
         c.c_customer_id,
         c.c_email_address,
         c.c_first_name,
         c.c_last_name,
         regexp_extract(c.c_email_address, '@(.+)$', 1) AS email_domain
  FROM tpcds.customer c
  TABLESAMPLE BERNOULLI (10)
  WHERE regexp_like(c.c_email_address, '^.+@.+\\.(com|net|org)$')
    AND (c.c_first_name LIKE '%a%' OR c.c_last_name LIKE '%a%')
),
customer_lateral AS (
  SELECT sc.*,
         concat(sc.c_first_name, ' ', sc.c_last_name) AS full_name,
         substring(sc.c_first_name FROM 1 FOR 1) AS first_initial,
         l.last_prefix
  FROM sampled_customers sc
  CROSS JOIN LATERAL (
      SELECT substring(sc.c_last_name FROM 1 FOR 2) AS last_prefix
  ) l
),
catalog_agg AS (
  SELECT cs.cs_bill_customer_sk AS customer_sk,
         sum(cs.cs_net_paid) AS total_net_paid,
         sum(cs.cs_net_profit) AS total_profit,
         count(*) AS order_cnt
  FROM tpcds.catalog_sales cs
  JOIN customer_lateral cl ON cs.cs_bill_customer_sk = cl.c_customer_sk
  JOIN tpcds.ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
  WHERE sm.sm_code LIKE 'A%'
  GROUP BY cs.cs_bill_customer_sk
),
web_agg AS (
  SELECT ws.ws_bill_customer_sk AS customer_sk,
         sum(ws.ws_net_paid) AS total_net_paid,
         sum(ws.ws_net_profit) AS total_profit,
         count(*) AS order_cnt
  FROM tpcds.web_sales ws
  JOIN customer_lateral cl ON ws.ws_bill_customer_sk = cl.c_customer_sk
  GROUP BY ws.ws_bill_customer_sk
),
sales_union AS (
  SELECT customer_sk, total_net_paid, total_profit, order_cnt
  FROM catalog_agg
  UNION DISTINCT
  SELECT customer_sk, total_net_paid, total_profit, order_cnt
  FROM web_agg
),
customers_with_returns AS (
  SELECT DISTINCT cs.cs_bill_customer_sk AS customer_sk
  FROM tpcds.catalog_sales cs
  JOIN tpcds.web_returns wr ON cs.cs_order_number = wr.wr_order_number
  JOIN customer_lateral cl ON cs.cs_bill_customer_sk = cl.c_customer_sk
),
eligible_customers AS (
  SELECT su.customer_sk,
         su.total_net_paid,
         su.total_profit,
         su.order_cnt
  FROM sales_union su
  WHERE su.customer_sk IN (
        SELECT su.customer_sk
        FROM sales_union su
        EXCEPT
        SELECT cwr.customer_sk
        FROM customers_with_returns cwr
  )
)
SELECT ec.customer_sk,
       cl.c_customer_id,
       cl.full_name,
       cl.email_domain,
       ec.total_net_paid,
       ec.total_profit,
       ec.order_cnt
FROM eligible_customers ec
JOIN customer_lateral cl ON ec.customer_sk = cl.c_customer_sk
ORDER BY ec.total_profit DESC
LIMIT 100
