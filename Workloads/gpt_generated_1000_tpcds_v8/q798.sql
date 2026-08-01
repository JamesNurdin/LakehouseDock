WITH
  -- Aggregate total paid per customer and per household buying potential using GROUPING SETS
  sales_agg AS (
    SELECT
      c.c_customer_sk,
      hd.hd_buy_potential,
      SUM(cs.cs_net_paid) AS total_paid
    FROM catalog_sales cs
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    GROUP BY GROUPING SETS ((c.c_customer_sk, hd.hd_buy_potential), (hd.hd_buy_potential))
  ),

  -- Rank customers within each buying‑potential bucket
  sales_rank AS (
    SELECT
      c_customer_sk,
      hd_buy_potential,
      total_paid,
      ROW_NUMBER() OVER (PARTITION BY hd_buy_potential ORDER BY total_paid DESC) AS rank_in_potential
    FROM sales_agg
    WHERE c_customer_sk IS NOT NULL
  ),

  -- Customers that have at least one web return during business hours (9‑17)
  returns_customers AS (
    SELECT DISTINCT wr.wr_returning_customer_sk AS customer_sk
    FROM web_returns wr
    JOIN time_dim td ON wr.wr_returned_time_sk = td.t_time_sk
    WHERE td.t_hour BETWEEN 9 AND 17
  ),

  -- Customers whose rank within their buying‑potential bucket is greater than 5 (low‑rank set)
  low_rank_customers AS (
    SELECT c_customer_sk AS customer_sk
    FROM sales_rank
    WHERE rank_in_potential > 5
  ),

  -- Customers living in low‑income bands (upper bound < 50000) – will be excluded later
  excluded_customers AS (
    SELECT c.c_customer_sk AS customer_sk
    FROM customer c
    JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE ib.ib_upper_bound < 50000
  )

SELECT *
FROM (
  -- INTERSECT: customers who both bought (with high spending) and returned items
  SELECT customer_sk
  FROM (
    SELECT c_customer_sk AS customer_sk
    FROM sales_rank
    WHERE total_paid > (
      SELECT AVG(total_paid)
      FROM sales_agg
      WHERE hd_buy_potential = '501-1000'
    )
  ) sr
  INTERSECT
  SELECT customer_sk
  FROM returns_customers
) intersect_set

UNION ALL

SELECT customer_sk
FROM low_rank_customers

EXCEPT

SELECT customer_sk
FROM excluded_customers

LIMIT 100
