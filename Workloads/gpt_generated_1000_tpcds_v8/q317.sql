WITH sr_sample AS (
   SELECT *
   FROM store_returns TABLESAMPLE BERNOULLI (10)
),
joined1 AS (
   SELECT
       sr.sr_ticket_number,
       sr.sr_return_amt,
       sr.sr_return_quantity,
       sr.sr_returned_date_sk,
       sr.sr_return_time_sk,
       sr.sr_reason_sk,
       sr.sr_customer_sk,
       d_ret.d_date,
       d_ret.d_year,
       t.t_hour,
       t.t_am_pm,
       r.r_reason_desc,
       cc.cc_name,
       cc.cc_class,
       cc.cc_manager
   FROM sr_sample sr
   JOIN date_dim d_ret
     ON sr.sr_returned_date_sk = d_ret.d_date_sk
   JOIN time_dim t
     ON sr.sr_return_time_sk = t.t_time_sk
   JOIN reason r
     ON sr.sr_reason_sk = r.r_reason_sk
   JOIN call_center cc
     ON cc.cc_closed_date_sk = d_ret.d_date_sk
   WHERE d_ret.d_year = 2002                                 -- predicate 1
     AND t.t_hour BETWEEN 8 AND 18                           -- predicate 2
     AND t.t_am_pm = 'PM'                                    -- predicate 3
     AND sr.sr_return_amt > 100                              -- predicate 4
     AND r.r_reason_desc LIKE '%product%'                    -- predicate 5
     AND cc.cc_class = 'large'                               -- predicate 6
     AND cc.cc_manager = 'Jack Little'                       -- predicate 7
     AND EXISTS (
         SELECT 1
         FROM store_returns sr2
         WHERE sr2.sr_customer_sk = sr.sr_customer_sk
           AND sr2.sr_return_amt > sr.sr_return_amt
     )
),
ranked AS (
   SELECT
       j.*, 
       ROW_NUMBER() OVER (ORDER BY j.sr_return_amt DESC) AS global_row_num,
       RANK() OVER (PARTITION BY j.cc_class ORDER BY j.sr_return_amt DESC) AS class_rank,
       (
           SELECT COUNT(*)
           FROM store_returns sr3
           WHERE sr3.sr_customer_sk = j.sr_customer_sk
             AND sr3.sr_return_amt > j.sr_return_amt
       ) AS higher_customer_returns
   FROM joined1 j
),
unioned AS (
   SELECT
       global_row_num,
       class_rank,
       higher_customer_returns,
       cc_name,
       cc_class,
       cc_manager,
       d_year,
       t_hour,
       r_reason_desc,
       sr_return_amt
   FROM ranked
   WHERE class_rank <= 5

   UNION DISTINCT

   SELECT
       global_row_num,
       class_rank,
       higher_customer_returns,
       cc_name,
       cc_class,
       cc_manager,
       d_year,
       t_hour,
       r_reason_desc,
       sr_return_amt
   FROM ranked
   WHERE sr_return_amt > 500
)
SELECT *
FROM unioned
ORDER BY sr_return_amt DESC
LIMIT 100
