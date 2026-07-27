WITH sub_a AS (
   SELECT
       wr.wr_returning_hdemo_sk AS returning_hdemo_sk,
       SUM(wr.wr_return_amt) AS total_return_amt,
       COUNT(*) AS cnt,
       MIN(t.t_hour) AS earliest_hour,
       (SELECT MAX(wr2.wr_return_quantity)
        FROM web_returns wr2
        WHERE wr2.wr_returning_hdemo_sk = wr.wr_returning_hdemo_sk) AS max_qty_by_hdemo,
       AVG(wr.wr_fee) AS avg_fee
   FROM web_returns wr
   JOIN time_dim t
       ON wr.wr_returned_time_sk = t.t_time_sk
   WHERE t.t_second BETWEEN 5 AND 15
     AND wr.wr_fee > 20
   GROUP BY wr.wr_returning_hdemo_sk
),
sub_b AS (
   SELECT
       wr.wr_returning_hdemo_sk AS returning_hdemo_sk,
       SUM(wr.wr_return_amt) AS total_return_amt,
       COUNT(*) AS cnt,
       MIN(t.t_hour) AS earliest_hour,
       (SELECT MAX(wr2.wr_return_quantity)
        FROM web_returns wr2
        WHERE wr2.wr_returning_hdemo_sk = wr.wr_returning_hdemo_sk) AS max_qty_by_hdemo,
       AVG(wr.wr_fee) AS avg_fee
   FROM web_returns wr
   JOIN time_dim t
       ON wr.wr_returned_time_sk = t.t_time_sk
   WHERE t.t_am_pm = 'PM'
     AND wr.wr_reversed_charge < 100
   GROUP BY wr.wr_returning_hdemo_sk
),
union_all AS (
   SELECT * FROM sub_a
   UNION ALL
   SELECT * FROM sub_b
)
SELECT DISTINCT
    returning_hdemo_sk,
    total_return_amt,
    cnt,
    earliest_hour,
    max_qty_by_hdemo,
    avg_fee
FROM union_all
ORDER BY total_return_amt DESC
LIMIT 100
