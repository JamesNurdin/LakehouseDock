-- Goal: Compare return behavior from catalog and web channels per customer salutation, using sampling, windowing, subqueries, and set operations.
WITH
  cr_cust AS (
    SELECT
      cr.cr_order_number,
      cr.cr_return_amount,
      cr.cr_return_ship_cost,
      cr.cr_return_quantity,
      c.c_customer_sk,
      c.c_salutation,
      c.c_birth_year,
      ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY cr.cr_returned_date_sk DESC) AS rn_cr
    FROM catalog_returns cr
    FULL OUTER JOIN customer c
      ON cr.cr_refunded_customer_sk = c.c_customer_sk
    WHERE cr.cr_return_ship_cost > 100
      AND c.c_birth_year BETWEEN 1950 AND 1990
      AND c.c_salutation = 'Mr.'
  ),
  wr_wp AS (
    SELECT
      wr.wr_order_number,
      wr.wr_return_amt,
      wr.wr_return_ship_cost,
      wr.wr_return_quantity,
      wp.wp_web_page_sk,
      wp.wp_autogen_flag,
      wp.wp_rec_end_date,
      c.c_customer_sk,
      c.c_salutation,
      c.c_birth_year,
      ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY wr.wr_returned_date_sk DESC) AS rn_wr
    FROM web_returns wr
    JOIN web_page wp
      ON wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN customer c
      ON wr.wr_refunded_customer_sk = c.c_customer_sk
    WHERE wr.wr_return_amt > 50
      AND wp.wp_autogen_flag = 'Y'
      AND wp.wp_rec_end_date > DATE '2000-01-01'
  ),
  union_returns AS (
    SELECT
      cr_order_number AS order_number,
      cr_return_amount AS return_amount,
      cr_return_ship_cost AS ship_cost,
      cr_return_quantity AS quantity,
      c_customer_sk,
      c_salutation,
      c_birth_year,
      rn_cr AS row_num
    FROM cr_cust
    WHERE rn_cr = 1

    UNION DISTINCT

    SELECT
      wr_order_number,
      wr_return_amt,
      wr_return_ship_cost,
      wr_return_quantity,
      c_customer_sk,
      c_salutation,
      c_birth_year,
      rn_wr
    FROM wr_wp
    WHERE rn_wr = 1
  ),
  sampled AS (
    SELECT *
    FROM union_returns
    TABLESAMPLE BERNOULLI (10) -- 10 % random sample
  ),
  agg AS (
    SELECT
      c_salutation,
      COUNT(*) AS cnt_customers,
      SUM(return_amount) AS total_return_amount,
      AVG(ship_cost) AS avg_ship_cost,
      SUM(return_amount) / COUNT(*) AS avg_return_per_customer
    FROM sampled
    WHERE ship_cost IS NOT NULL
    GROUP BY c_salutation
    HAVING COUNT(*) > 5
  )
SELECT
  a.c_salutation,
  a.cnt_customers,
  a.total_return_amount,
  a.avg_ship_cost,
  a.avg_return_per_customer,
  (SELECT MAX(total_return_amount) FROM agg) AS max_total_return,
  ROW_NUMBER() OVER (ORDER BY a.total_return_amount DESC) AS global_rank
FROM agg a
WHERE a.total_return_amount > (SELECT AVG(total_return_amount) FROM agg)
ORDER BY a.total_return_amount DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY
