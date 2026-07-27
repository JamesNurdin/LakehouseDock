WITH refunded AS (
   SELECT
      c.c_customer_sk AS cust_sk,
      c.c_customer_id AS cust_id,
      cd.cd_credit_rating AS credit_rating,
      d.d_year AS year,
      SUM(wr.wr_return_amt) AS total_return_amt,
      COUNT(*) AS return_cnt,
      ROW_NUMBER() OVER (PARTITION BY d.d_year ORDER BY SUM(wr.wr_return_amt) DESC) AS rn_year
   FROM web_returns wr
   JOIN customer c ON wr.wr_refunded_customer_sk = c.c_customer_sk
   LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
   LEFT JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
   WHERE d.d_year = 2001
     AND wr.wr_return_amt > 100
     AND (cd.cd_credit_rating = 'Good' OR cd.cd_credit_rating IS NULL)
   GROUP BY c.c_customer_sk, c.c_customer_id, cd.cd_credit_rating, d.d_year
),
returning AS (
   SELECT
      c.c_customer_sk AS cust_sk,
      c.c_customer_id AS cust_id,
      cd.cd_credit_rating AS credit_rating,
      d.d_year AS year,
      SUM(wr.wr_return_amt) AS total_return_amt,
      COUNT(*) AS return_cnt,
      ROW_NUMBER() OVER (PARTITION BY d.d_year ORDER BY SUM(wr.wr_return_amt) DESC) AS rn_year
   FROM web_returns wr
   JOIN customer c ON wr.wr_returning_customer_sk = c.c_customer_sk
   LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
   LEFT JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
   WHERE d.d_year = 2001
     AND wr.wr_return_amt > 100
     AND cd.cd_dep_employed_count > 0
   GROUP BY c.c_customer_sk, c.c_customer_id, cd.cd_credit_rating, d.d_year
),
avg_return AS (
   SELECT AVG(total_return_amt) AS avg_amt
   FROM (
      SELECT SUM(wr_return_amt) AS total_return_amt
      FROM web_returns wr
      WHERE wr.wr_returned_date_sk IN (
         SELECT d_date_sk FROM date_dim WHERE d_year = 2001
      )
      GROUP BY wr.wr_returned_date_sk
   ) t
)
SELECT
   combined.cust_sk,
   combined.cust_id,
   COALESCE(combined.credit_rating, 'Unknown') AS credit_rating,
   combined.year,
   combined.total_return_amt,
   combined.return_cnt,
   combined.rn_year,
   CASE
      WHEN combined.total_return_amt > avg_return.avg_amt THEN 'Above Avg'
      ELSE 'Below Avg'
   END AS performance_bucket
FROM (
   SELECT * FROM refunded
   UNION ALL
   SELECT * FROM returning
) combined
CROSS JOIN avg_return
WHERE combined.rn_year <= 10
ORDER BY combined.year DESC, combined.total_return_amt DESC
LIMIT 100
