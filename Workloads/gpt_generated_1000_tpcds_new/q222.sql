WITH returns_agg AS (
  SELECT
    cr.cr_refunded_customer_sk AS customer_sk,
    SUM(cr.cr_return_amount) AS total_return_amount,
    COUNT(*) AS return_cnt
  FROM catalog_returns cr
  JOIN customer c
    ON cr.cr_refunded_customer_sk = c.c_customer_sk
  WHERE c.c_salutation = 'Mr.'
    AND cr.cr_return_amount > 10.00
  GROUP BY cr.cr_refunded_customer_sk
),
sales_agg AS (
  SELECT
    ws.ws_bill_customer_sk AS customer_sk,
    SUM(ws.ws_net_paid) AS total_sales_amount,
    COUNT(*) AS sales_cnt
  FROM web_sales ws
  JOIN customer c
    ON ws.ws_bill_customer_sk = c.c_customer_sk
  JOIN web_site w
    ON ws.ws_web_site_sk = w.web_site_sk
  WHERE w.web_company_name = 'pri'
    AND ws.ws_net_paid > 0
  GROUP BY ws.ws_bill_customer_sk
),
full_combined AS (
  SELECT
    COALESCE(r.customer_sk, s.customer_sk) AS customer_sk,
    r.total_return_amount,
    s.total_sales_amount
  FROM returns_agg r
  FULL OUTER JOIN sales_agg s
    ON r.customer_sk = s.customer_sk
),
returns_not_sales AS (
  SELECT customer_sk FROM returns_agg
  EXCEPT
  SELECT customer_sk FROM sales_agg
),
high_activity AS (
  SELECT
    f.customer_sk,
    f.total_return_amount,
    f.total_sales_amount,
    (SELECT AVG(total_return_amount) FROM returns_agg) AS avg_return_amount
  FROM full_combined f
  WHERE f.total_return_amount > (SELECT AVG(total_return_amount) FROM returns_agg)
     OR f.total_sales_amount > (SELECT AVG(total_sales_amount) FROM sales_agg)
)
SELECT
  ha.customer_sk,
  ha.total_return_amount,
  ha.total_sales_amount,
  ha.avg_return_amount
FROM high_activity ha
WHERE ha.customer_sk IN (SELECT customer_sk FROM returns_not_sales)
ORDER BY ha.total_return_amount DESC NULLS LAST,
         ha.total_sales_amount DESC NULLS LAST
LIMIT 100
