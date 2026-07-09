WITH sales_by_promo_shift AS (
    SELECT d.d_date_sk,
           d.d_current_quarter,
           p.p_channel_tv,
           p.p_channel_email,
           t.t_shift,
           SUM(ss.ss_net_profit) AS total_net_profit,
           SUM(ss.ss_ext_sales_price) AS total_sales,
           COUNT(*) AS sales_txns
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    WHERE d.d_current_quarter = 'Y'
      AND p.p_discount_active = 'Y'
    GROUP BY d.d_date_sk, d.d_current_quarter, p.p_channel_tv, p.p_channel_email, t.t_shift
),
returns_by_shift AS (
    SELECT d.d_date_sk,
           t.t_shift,
           SUM(wr.wr_net_loss) AS total_net_loss,
           SUM(wr.wr_return_amt_inc_tax) AS total_return_amount,
           COUNT(*) AS return_txns
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN time_dim t ON wr.wr_returned_time_sk = t.t_time_sk
    WHERE d.d_current_quarter = 'Y'
    GROUP BY d.d_date_sk, t.t_shift
)
SELECT s.d_current_quarter,
       s.p_channel_tv,
       s.p_channel_email,
       s.t_shift,
       s.total_sales,
       s.total_net_profit,
       COALESCE(r.total_return_amount, 0) AS total_return_amount,
       s.total_net_profit - COALESCE(r.total_net_loss, 0) AS net_profit_after_returns,
       ROUND((s.total_net_profit - COALESCE(r.total_net_loss, 0)) / NULLIF(s.total_sales, 0) * 100, 2) AS profit_margin_pct,
       RANK() OVER (ORDER BY (s.total_net_profit - COALESCE(r.total_net_loss, 0)) DESC) AS profit_rank
FROM sales_by_promo_shift s
LEFT JOIN returns_by_shift r
  ON s.d_date_sk = r.d_date_sk
 AND s.t_shift = r.t_shift
WHERE s.total_sales > 1000
ORDER BY profit_rank
LIMIT 10
