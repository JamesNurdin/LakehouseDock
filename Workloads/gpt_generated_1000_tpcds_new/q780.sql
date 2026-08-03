WITH
  -- Sample a small random fraction of each source table
  cust_sample AS (
    SELECT *
    FROM customer
    TABLESAMPLE BERNOULLI (10)   -- approx. 10% of rows
  ),
  returns_sample AS (
    SELECT *
    FROM web_returns
    TABLESAMPLE BERNOULLI (10)
  ),

  -- Join the two tables using a valid join rule and apply at least five predicates
  joined AS (
    SELECT
      c.c_customer_sk,
      c.c_first_name,
      c.c_last_name,
      c.c_birth_year,
      c.c_preferred_cust_flag,
      wr.wr_return_amt_inc_tax,
      wr.wr_return_quantity,
      wr.wr_return_ship_cost,
      wr.wr_returned_date_sk
    FROM cust_sample c
    JOIN returns_sample wr
      ON wr.wr_returning_customer_sk = c.c_customer_sk
    WHERE wr.wr_return_amt_inc_tax > 100                -- predicate 1
      AND wr.wr_return_quantity >= 1                  -- predicate 2
      AND wr.wr_return_ship_cost < 500                -- predicate 3
      AND c.c_birth_year BETWEEN 1950 AND 1990       -- predicate 4
      AND c.c_preferred_cust_flag = 'Y'               -- predicate 5
  ),

  -- Key set of all customers that appear in the joined result
  customers_with_returns AS (
    SELECT DISTINCT c_customer_sk FROM joined
  ),
  -- Key set of customers whose returns have a relatively high shipping cost
  customers_with_high_ship AS (
    SELECT DISTINCT c_customer_sk FROM joined WHERE wr_return_ship_cost > 300
  ),

  -- Subtract one key set from another using EXCEPT
  except_keys AS (
    SELECT c_customer_sk FROM customers_with_returns
    EXCEPT
    SELECT c_customer_sk FROM customers_with_high_ship
  ),

  -- Intersect the two key sets using INTERSECT
  intersect_keys AS (
    SELECT c_customer_sk FROM customers_with_returns
    INTERSECT
    SELECT c_customer_sk FROM customers_with_high_ship
  ),

  -- Add a window rank and a lateral sub‑query that computes the customer‑wide average return amount
  ranked AS (
    SELECT
      j.c_customer_sk,
      j.c_first_name,
      j.c_last_name,
      j.c_birth_year,
      j.c_preferred_cust_flag,
      j.wr_return_amt_inc_tax,
      j.wr_return_quantity,
      j.wr_return_ship_cost,
      j.wr_returned_date_sk,
      ROW_NUMBER() OVER (PARTITION BY j.c_customer_sk ORDER BY j.wr_returned_date_sk DESC) AS rn_return_seq,
      RANK() OVER (ORDER BY j.wr_return_amt_inc_tax DESC) AS amt_rank,
      -- LATERAL sub‑query for the average return amount of the same customer
      lt.avg_return_amt
    FROM joined j
    CROSS JOIN LATERAL (
      SELECT avg(wr2.wr_return_amt_inc_tax) AS avg_return_amt
      FROM web_returns wr2
      WHERE wr2.wr_returning_customer_sk = j.c_customer_sk
    ) lt
  ),

  -- Keep rows that belong to the EXCEPT key set
  except_rows AS (
    SELECT *, 'EXCEPT' AS src_tag
    FROM ranked
    WHERE c_customer_sk IN (SELECT c_customer_sk FROM except_keys)
  ),
  -- Keep rows that belong to the INTERSECT key set
  intersect_rows AS (
    SELECT *, 'INTERSECT' AS src_tag
    FROM ranked
    WHERE c_customer_sk IN (SELECT c_customer_sk FROM intersect_keys)
  ),

  -- Combine the two streams
  final_set AS (
    SELECT * FROM except_rows
    UNION ALL
    SELECT * FROM intersect_rows
  )

SELECT
  c_customer_sk,
  c_first_name,
  c_last_name,
  c_birth_year,
  c_preferred_cust_flag,
  wr_return_amt_inc_tax,
  wr_return_quantity,
  wr_return_ship_cost,
  wr_returned_date_sk,
  rn_return_seq,
  amt_rank,
  avg_return_amt,
  src_tag
FROM final_set
ORDER BY amt_rank
LIMIT 100
