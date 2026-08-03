WITH sr_agg AS (
   SELECT
       sr_reason_sk,
       sr_returned_date_sk,
       sr_return_time_sk,
       COUNT(*) AS cnt_returns,
       SUM(sr_return_amt) AS total_return_amt,
       COUNT(DISTINCT sr_customer_sk) AS distinct_customers,
       SUM(DISTINCT sr_return_amt) AS sum_distinct_return_amt
   FROM store_returns
   WHERE sr_return_tax > 5
     AND sr_returned_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_current_month = 'Y')
   GROUP BY sr_reason_sk, sr_returned_date_sk, sr_return_time_sk
),
joined AS (
   SELECT
       r.r_reason_desc,
       d.d_year,
       d.d_month_seq,
       t.t_hour,
       sr.cnt_returns,
       sr.total_return_amt,
       sr.distinct_customers,
       sr.sum_distinct_return_amt,
       split(r.r_reason_desc, ' ') AS words_array
   FROM sr_agg sr
   JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
   JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
   JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
   WHERE d.d_year = 2001
     AND d.d_month_seq BETWEEN 120 AND 130
     AND d.d_week_seq = 10
     AND t.t_hour IN (9, 10, 11)
     AND r.r_reason_id LIKE 'AAAAAAA%'
     AND r.r_reason_sk IN (
         SELECT r2.r_reason_sk FROM reason r2 WHERE r2.r_reason_desc LIKE '%product%'
     )
)
SELECT
   j.r_reason_desc,
   j.d_year,
   j.t_hour,
   word,
   SUM(j.total_return_amt) AS sum_return_amt,
   COUNT(DISTINCT j.distinct_customers) AS cnt_distinct_customers,
   AVG(j.cnt_returns) AS avg_cnt_returns,
   (SELECT COUNT(DISTINCT sr_customer_sk) FROM store_returns) AS overall_distinct_customers
FROM joined j
CROSS JOIN UNNEST(j.words_array) AS t(word)
GROUP BY j.r_reason_desc, j.d_year, j.t_hour, word
HAVING SUM(j.total_return_amt) > 1000
ORDER BY sum_return_amt DESC
LIMIT 100
