WITH returns_a AS (
   SELECT
      d.d_date AS return_date,
      wr.wr_return_amt AS return_amount,
      r.r_reason_desc,
      c.c_customer_id AS customer_id,
      ROW_NUMBER() OVER (PARTITION BY r.r_reason_desc ORDER BY wr.wr_return_amt DESC) AS rn
   FROM web_returns wr
   JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
   JOIN time_dim t ON wr.wr_returned_time_sk = t.t_time_sk
   JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
   JOIN customer c ON wr.wr_refunded_customer_sk = c.c_customer_sk
   WHERE r.r_reason_id = 'AAAAAAAAABAAAAAA'
     AND d.d_year = 2002
),
returns_b AS (
   SELECT
      d.d_date AS return_date,
      wr.wr_return_amt AS return_amount,
      r.r_reason_desc,
      c.c_customer_id AS customer_id,
      ROW_NUMBER() OVER (PARTITION BY r.r_reason_desc ORDER BY wr.wr_return_amt DESC) AS rn
   FROM web_returns wr
   JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
   JOIN time_dim t ON wr.wr_returned_time_sk = t.t_time_sk
   JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
   JOIN customer c ON wr.wr_refunded_customer_sk = c.c_customer_sk
   WHERE r.r_reason_id = 'AAAAAAAAGAAAAAAA'
     AND d.d_year = 2002
)
SELECT *
FROM returns_a
UNION ALL
SELECT *
FROM returns_b
ORDER BY return_date DESC, rn
LIMIT 100
