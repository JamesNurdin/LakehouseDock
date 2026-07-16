WITH agg AS (
  SELECT
    i.i_category,
    i.i_brand,
    SUM(wr.wr_net_loss) AS total_net_loss,
    AVG(wr.wr_return_quantity) AS avg_return_qty,
    COUNT(DISTINCT c_ref.c_customer_sk) AS distinct_refunded_customers,
    COUNT(DISTINCT c_ret.c_customer_sk) AS distinct_returning_customers
  FROM web_returns wr
  JOIN item i ON wr.wr_item_sk = i.i_item_sk
  JOIN customer c_ref ON wr.wr_refunded_customer_sk = c_ref.c_customer_sk
  JOIN customer c_ret ON wr.wr_returning_customer_sk = c_ret.c_customer_sk
  WHERE c_ref.c_birth_year IN (1950, 1960)
    AND c_ret.c_birth_year IN (1950, 1960)
    AND i.i_brand_id IN (1, 2)
    AND wr.wr_returned_date_sk BETWEEN 2450000 AND 2455000
  GROUP BY i.i_category, i.i_brand
)
SELECT
  i_category,
  i_brand,
  total_net_loss,
  avg_return_qty,
  distinct_refunded_customers,
  distinct_returning_customers,
  RANK() OVER (ORDER BY total_net_loss DESC) AS loss_rank
FROM agg
WHERE total_net_loss > 1000
ORDER BY total_net_loss DESC
LIMIT 50
