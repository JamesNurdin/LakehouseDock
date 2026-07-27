WITH promo_start AS (
   SELECT p.p_promo_sk,
          p.p_promo_name,
          p.p_start_date_sk,
          p.p_channel_press,
          p.p_channel_event,
          p.p_cost
   FROM promotion p
   WHERE p.p_channel_press = 'N'
     AND p.p_channel_event = 'N'
     AND p.p_cost > 0
),
date_ret AS (
   SELECT d.d_date_sk,
          d.d_year,
          d.d_month_seq,
          d.d_following_holiday,
          d.d_same_day_ly
   FROM date_dim d
   WHERE d.d_year = 2001
     AND d.d_following_holiday = 'N'
     AND d.d_same_day_ly = 2414658
),
wr_filtered AS (
   SELECT wr.wr_returned_date_sk,
          wr.wr_returning_customer_sk,
          wr.wr_return_quantity,
          wr.wr_return_amt,
          wr.wr_net_loss
   FROM web_returns wr
   WHERE wr.wr_return_quantity > 1
     AND wr.wr_return_amt > 100
)
SELECT
    p.p_promo_name,
    d.d_year,
    d.d_month_seq,
    COUNT(*) AS total_returns,
    SUM(wr.wr_return_amt) AS sum_return_amount,
    AVG(wr.wr_return_quantity) AS avg_return_qty,
    MIN(wr.wr_net_loss) AS min_net_loss,
    MAX(wr.wr_net_loss) AS max_net_loss,
    COUNT(DISTINCT wr.wr_returning_customer_sk) AS distinct_customers
FROM wr_filtered wr
JOIN date_ret d
  ON wr.wr_returned_date_sk = d.d_date_sk
JOIN promo_start p
  ON p.p_start_date_sk = d.d_date_sk
GROUP BY
    p.p_promo_name,
    d.d_year,
    d.d_month_seq
ORDER BY sum_return_amount DESC
LIMIT 100
