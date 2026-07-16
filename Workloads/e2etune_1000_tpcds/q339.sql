WITH sales_agg AS (
    SELECT s.s_store_id,
           s.s_store_name,
           t.t_hour,
           t.t_shift,
           SUM(ss.ss_net_paid) AS total_sales,
           SUM(ss.ss_net_profit) AS total_profit,
           SUM(ss.ss_quantity) AS total_quantity
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    WHERE s.s_country = 'United States' AND t.t_shift = 'Evening'
    GROUP BY s.s_store_id, s.s_store_name, t.t_hour, t.t_shift
),
returns_agg AS (
    SELECT s.s_store_id,
           t.t_hour,
           SUM(sr.sr_net_loss) AS total_return_loss,
           SUM(sr.sr_refunded_cash) AS total_refunded
    FROM store_returns sr
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
    WHERE s.s_country = 'United States' AND t.t_shift = 'Evening'
    GROUP BY s.s_store_id, t.t_hour
)
SELECT sa.s_store_id,
       sa.s_store_name,
       sa.t_hour,
       sa.t_shift,
       sa.total_sales,
       sa.total_profit,
       COALESCE(ra.total_return_loss, 0) AS total_return_loss,
       COALESCE(ra.total_refunded, 0) AS total_refunded,
       (sa.total_profit - COALESCE(ra.total_return_loss, 0)) AS net_profit_after_returns,
       RANK() OVER (ORDER BY (sa.total_profit - COALESCE(ra.total_return_loss, 0)) DESC) AS profit_rank
FROM sales_agg sa
LEFT JOIN returns_agg ra
  ON sa.s_store_id = ra.s_store_id AND sa.t_hour = ra.t_hour
WHERE (sa.total_profit - COALESCE(ra.total_return_loss, 0)) > 0
ORDER BY net_profit_after_returns DESC
LIMIT 20
