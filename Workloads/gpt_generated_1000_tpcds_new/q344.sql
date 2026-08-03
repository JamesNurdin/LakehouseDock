WITH sampled_wr AS (
       SELECT *
       FROM web_returns
       TABLESAMPLE BERNOULLI (10)
       WHERE wr_return_quantity > 0
   ),
   joined AS (
       SELECT
           wr.wr_order_number,
           wr.wr_return_amt,
           wr.wr_net_loss,
           d.d_year,
           d.d_month_seq,
           t.t_hour,
           r.r_reason_desc,
           p.p_promo_name,
           wr.wr_reversed_charge
       FROM sampled_wr AS wr
       JOIN date_dim AS d
         ON wr.wr_returned_date_sk = d.d_date_sk
       JOIN time_dim AS t
         ON wr.wr_returned_time_sk = t.t_time_sk
       JOIN reason AS r
         ON wr.wr_reason_sk = r.r_reason_sk
       JOIN promotion AS p
         ON p.p_start_date_sk = d.d_date_sk
       WHERE d.d_qoy = 3
         AND d.d_current_day = 'N'
         AND t.t_minute IN (3, 5, 7, 9, 11)
         AND p.p_channel_email = 'Y'
         AND wr.wr_reversed_charge > 100
   ),
   ranked AS (
       SELECT
           wr_order_number,
           wr_return_amt,
           wr_net_loss,
           d_year,
           d_month_seq,
           t_hour,
           r_reason_desc,
           p_promo_name,
           ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY wr_return_amt DESC) AS rn
       FROM joined
   )
SELECT wr_order_number,
       wr_return_amt,
       wr_net_loss,
       d_year,
       d_month_seq,
       t_hour,
       r_reason_desc,
       p_promo_name,
       rn
FROM ranked
WHERE rn <= 5
INTERSECT
SELECT wr_order_number,
       wr_return_amt,
       wr_net_loss,
       d_year,
       d_month_seq,
       t_hour,
       r_reason_desc,
       p_promo_name,
       rn
FROM ranked
WHERE rn = 3
EXCEPT
SELECT wr_order_number,
       wr_return_amt,
       wr_net_loss,
       d_year,
       d_month_seq,
       t_hour,
       r_reason_desc,
       p_promo_name,
       rn
FROM ranked
WHERE rn = 1
ORDER BY d_year, rn
LIMIT 100
