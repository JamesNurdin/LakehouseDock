WITH
  scalar_avg AS (
    SELECT avg(cs.cs_net_paid) AS avg_net_paid
    FROM catalog_sales cs
    WHERE cs.cs_sold_date_sk IN (
      SELECT d.d_date_sk
      FROM date_dim d
      WHERE d.d_year = 2001
    )
  ),
  catalog_customers AS (
    SELECT DISTINCT cs.cs_bill_customer_sk AS customer_sk
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND cs.cs_net_paid > (SELECT avg_net_paid FROM scalar_avg)
  ),
  web_customers AS (
    SELECT DISTINCT ws.ws_bill_customer_sk AS customer_sk
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND ws.ws_net_paid > (SELECT avg_net_paid FROM scalar_avg)
  ),
  intersect_customers AS (
    SELECT customer_sk FROM catalog_customers
    INTERSECT
    SELECT customer_sk FROM web_customers
  )
SELECT
  ic.customer_sk,
  COUNT(DISTINCT cs.cs_order_number) AS catalog_orders,
  COUNT(DISTINCT ws.ws_order_number) AS web_orders,
  ROW_NUMBER() OVER (ORDER BY COUNT(DISTINCT cs.cs_order_number) DESC) AS rank
FROM intersect_customers ic
LEFT JOIN catalog_sales cs
  ON cs.cs_bill_customer_sk = ic.customer_sk
  AND cs.cs_sold_date_sk IN (
    SELECT d.d_date_sk
    FROM date_dim d
    WHERE d.d_year = 2001
  )
LEFT JOIN web_sales ws
  ON ws.ws_bill_customer_sk = ic.customer_sk
  AND ws.ws_sold_date_sk IN (
    SELECT d.d_date_sk
    FROM date_dim d
    WHERE d.d_year = 2001
  )
GROUP BY ic.customer_sk
HAVING COUNT(DISTINCT cs.cs_order_number) >= 5
ORDER BY rank
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY
