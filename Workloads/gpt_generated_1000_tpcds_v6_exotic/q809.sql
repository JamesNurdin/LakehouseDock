WITH refunded AS (
   SELECT DISTINCT
          cust_r.c_customer_id        AS customer_id,
          cust_r.c_first_name        AS first_name,
          cust_r.c_last_name         AS last_name,
          wr.wr_return_amt           AS wr_return_amt,
          td.t_hour                  AS hour,
          'refunded'                 AS role
   FROM web_returns wr
   JOIN time_dim td
        ON wr.wr_returned_time_sk = td.t_time_sk
   JOIN customer cust_r
        ON wr.wr_refunded_customer_sk = cust_r.c_customer_sk
   WHERE wr.wr_return_amt > 100
     AND td.t_am_pm = 'PM'
),
returning AS (
   SELECT DISTINCT
          cust_ret.c_customer_id    AS customer_id,
          cust_ret.c_first_name    AS first_name,
          cust_ret.c_last_name     AS last_name,
          wr.wr_return_amt         AS wr_return_amt,
          td.t_hour                AS hour,
          'returning'              AS role
   FROM web_returns wr
   JOIN time_dim td
        ON wr.wr_returned_time_sk = td.t_time_sk
   JOIN customer cust_ret
        ON wr.wr_returning_customer_sk = cust_ret.c_customer_sk
   WHERE wr.wr_return_amt BETWEEN 50 AND 200
     AND td.t_sub_shift = 'morning'
)
SELECT DISTINCT *
FROM (
   SELECT * FROM refunded
   UNION ALL
   SELECT * FROM returning
) AS combined
ORDER BY hour, role, wr_return_amt DESC
LIMIT 100
