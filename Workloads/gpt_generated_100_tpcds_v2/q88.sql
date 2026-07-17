WITH ss_promo_agg AS (
    SELECT
        td.t_time_sk,
        td.t_hour,
        SUM(ss.ss_net_profit) AS total_net_profit,
        SUM(CASE WHEN p.p_channel_demo = 'N' THEN ss.ss_net_profit ELSE 0 END) AS demo_channel_profit,
        COUNT(*) AS sales_txn_count
    FROM store_sales ss
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    GROUP BY td.t_time_sk, td.t_hour
), wr_agg AS (
    SELECT
        td.t_time_sk,
        td.t_hour,
        SUM(wr.wr_net_loss) AS total_net_loss,
        SUM(wr.wr_return_amt) AS total_return_amount,
        COUNT(*) AS return_txn_count
    FROM web_returns wr
    JOIN time_dim td ON wr.wr_returned_time_sk = td.t_time_sk
    GROUP BY td.t_time_sk, td.t_hour
)
SELECT
    COALESCE(ss.t_hour, wr.t_hour) AS hour_of_day,
    COALESCE(ss.total_net_profit, 0) AS total_net_profit,
    COALESCE(ss.demo_channel_profit, 0) AS demo_channel_profit,
    COALESCE(wr.total_net_loss, 0) AS total_net_loss,
    (COALESCE(ss.total_net_profit, 0) - COALESCE(wr.total_net_loss, 0)) AS net_profit_minus_loss,
    CASE WHEN COALESCE(ss.total_net_profit, 0) > 0 THEN 'Profit' ELSE 'Loss' END AS profit_category,
    RANK() OVER (ORDER BY COALESCE(ss.total_net_profit, 0) DESC) AS profit_rank,
    DENSE_RANK() OVER (ORDER BY COALESCE(ss.total_net_profit, 0) DESC) AS profit_dense_rank,
    ROW_NUMBER() OVER (ORDER BY COALESCE(ss.total_net_profit, 0) DESC) AS profit_row_num,
    AVG(COALESCE(ss.total_net_profit, 0)) OVER (
        ORDER BY COALESCE(ss.t_hour, wr.t_hour)
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ) AS moving_avg_profit_last_3_hours,
    SUM(COALESCE(ss.demo_channel_profit, 0)) OVER (
        ORDER BY COALESCE(ss.t_hour, wr.t_hour)
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_demo_channel_profit
FROM ss_promo_agg ss
FULL OUTER JOIN wr_agg wr ON ss.t_time_sk = wr.t_time_sk
WHERE COALESCE(ss.t_hour, wr.t_hour) IS NOT NULL
ORDER BY hour_of_day
