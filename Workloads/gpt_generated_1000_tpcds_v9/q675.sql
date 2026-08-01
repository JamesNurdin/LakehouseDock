WITH store_sales_agg AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        t.t_hour,
        SUM(ss.ss_net_profit) AS sum_store_net_profit,
        SUM(ss.ss_quantity) AS sum_store_quantity
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    WHERE s.s_state = 'CA'
      AND s.s_market_id IN (1, 2, 3)
      AND ss.ss_quantity > 1
      AND t.t_hour BETWEEN 8 AND 18
    GROUP BY s.s_store_id, s.s_store_name, t.t_hour
),
web_sales_agg AS (
    SELECT
        t.t_hour,
        SUM(ws.ws_net_profit) AS sum_web_net_profit,
        SUM(ws.ws_quantity) AS sum_web_quantity
    FROM web_sales ws
    JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    WHERE ws.ws_quantity >= 2
      AND t.t_hour BETWEEN 8 AND 18
    GROUP BY t.t_hour
),
returns_agg AS (
    SELECT
        t.t_hour,
        SUM(wr.wr_net_loss) AS sum_return_net_loss,
        SUM(wr.wr_return_amt) AS sum_return_amt,
        COUNT(*) AS cnt_returns
    FROM web_returns wr
    JOIN time_dim t ON wr.wr_returned_time_sk = t.t_time_sk
    WHERE wr.wr_return_amt > 100.00
      AND t.t_hour BETWEEN 8 AND 18
    GROUP BY t.t_hour
)
SELECT
    ss.s_store_id,
    ss.s_store_name,
    ss.t_hour,
    ss.sum_store_net_profit,
    ws.sum_web_net_profit,
    COALESCE(r.sum_return_net_loss, 0) AS sum_return_net_loss,
    (ss.sum_store_net_profit + COALESCE(ws.sum_web_net_profit, 0) - COALESCE(r.sum_return_net_loss, 0)) AS total_net_profit,
    CASE
        WHEN ss.sum_store_net_profit + COALESCE(ws.sum_web_net_profit, 0) - COALESCE(r.sum_return_net_loss, 0) > 0 THEN 'Profit'
        ELSE 'Loss'
    END AS profit_flag,
    (
        SELECT SUM(wr2.wr_return_amt)
        FROM web_returns wr2
        JOIN time_dim t2 ON wr2.wr_returned_time_sk = t2.t_time_sk
        WHERE t2.t_hour = ss.t_hour
    ) AS total_return_amt_for_hour,
    (
        SELECT AVG(total_net_profit)
        FROM (
            SELECT
                ss2.sum_store_net_profit + COALESCE(ws2.sum_web_net_profit, 0) - COALESCE(r2.sum_return_net_loss, 0) AS total_net_profit
            FROM store_sales_agg ss2
            LEFT JOIN web_sales_agg ws2 ON ss2.t_hour = ws2.t_hour
            LEFT JOIN returns_agg r2 ON ss2.t_hour = r2.t_hour
        ) sub
    ) AS overall_avg_total_net_profit
FROM store_sales_agg ss
LEFT JOIN web_sales_agg ws ON ss.t_hour = ws.t_hour
LEFT JOIN returns_agg r ON ss.t_hour = r.t_hour
WHERE (ss.sum_store_net_profit + COALESCE(ws.sum_web_net_profit, 0) - COALESCE(r.sum_return_net_loss, 0)) > 0
ORDER BY total_net_profit DESC
LIMIT 100
