/*
  Goal: Rank customers by total net paid sales for the year 2001, limited to customers born between 1950 and 1970 and with sizable purchases. The query includes store information (only stores in CA, preserving sales without a matching store via a LEFT JOIN) and aggregates any return loss. It demonstrates outer‑join handling, multiple filters, aggregation, a CASE expression, and a window‑function rank.
*/
WITH sales_agg AS (
  SELECT
    c.c_customer_id,
    d_sold.d_year,
    s.s_store_name,
    SUM(cs.cs_net_paid)                         AS total_net_paid,
    SUM(COALESCE(sr.sr_net_loss, 0))            AS total_return_loss
  FROM catalog_sales cs
  JOIN customer c
    ON cs.cs_bill_customer_sk = c.c_customer_sk
  JOIN customer_address ca
    ON cs.cs_bill_addr_sk = ca.ca_address_sk
  JOIN date_dim d_sold
    ON cs.cs_sold_date_sk = d_sold.d_date_sk
  LEFT JOIN store_returns sr
    ON sr.sr_customer_sk = c.c_customer_sk
  LEFT JOIN store s
    ON sr.sr_store_sk = s.s_store_sk
  LEFT JOIN web_site w
    ON w.web_open_date_sk = d_sold.d_date_sk
  WHERE d_sold.d_year = 2001
    AND c.c_birth_year BETWEEN 1950 AND 1970
    AND cs.cs_net_paid > 1000
    AND (s.s_state = 'CA' OR s.s_state IS NULL)
  GROUP BY c.c_customer_id, d_sold.d_year, s.s_store_name
)
SELECT
  c_customer_id,
  d_year,
  s_store_name,
  total_net_paid,
  total_return_loss,
  RANK() OVER (PARTITION BY d_year ORDER BY total_net_paid DESC) AS revenue_rank,
  CASE WHEN total_return_loss > 0 THEN 'Has Returns' ELSE 'No Returns' END AS return_flag
FROM sales_agg
ORDER BY d_year, revenue_rank
LIMIT 100
