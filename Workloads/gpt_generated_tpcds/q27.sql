WITH
    sales_agg AS (
        SELECT
            s.s_store_sk,
            s.s_store_name,
            t.t_shift,
            SUM(ss.ss_net_profit) AS total_sales_net_profit,
            SUM(ss.ss_quantity) AS total_sales_quantity
        FROM store_sales ss
        JOIN store s ON ss.ss_store_sk = s.s_store_sk
        JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
        GROUP BY s.s_store_sk, s.s_store_name, t.t_shift
    ),
    returns_agg AS (
        SELECT
            s.s_store_sk,
            s.s_store_name,
            t.t_shift,
            SUM(sr.sr_net_loss) AS total_returns_net_loss,
            SUM(sr.sr_return_quantity) AS total_return_quantity
        FROM store_returns sr
        JOIN store s ON sr.sr_store_sk = s.s_store_sk
        JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
        GROUP BY s.s_store_sk, s.s_store_name, t.t_shift
    )
SELECT
    sa.s_store_sk,
    sa.s_store_name,
    sa.t_shift,
    sa.total_sales_net_profit,
    COALESCE(ra.total_returns_net_loss, 0) AS total_returns_net_loss,
    (sa.total_sales_net_profit - COALESCE(ra.total_returns_net_loss, 0)) AS net_profit_after_returns,
    sa.total_sales_quantity,
    COALESCE(ra.total_return_quantity, 0) AS total_return_quantity,
    CASE WHEN sa.total_sales_quantity > 0
        THEN COALESCE(ra.total_return_quantity, 0) * 1.0 / sa.total_sales_quantity
        ELSE 0
    END AS return_rate
FROM sales_agg sa
LEFT JOIN returns_agg ra
    ON sa.s_store_sk = ra.s_store_sk
    AND sa.t_shift = ra.t_shift
ORDER BY net_profit_after_returns DESC
LIMIT 100
