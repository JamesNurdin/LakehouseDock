WITH sales_by_time AS (
    SELECT
        t.t_hour AS hour,
        t.t_minute AS minute,
        SUM(cs.cs_ext_sales_price) AS total_sales_amount,
        SUM(cs.cs_net_profit) AS total_sales_profit,
        COUNT(*) AS sales_transactions
    FROM catalog_sales cs
    JOIN time_dim t
        ON cs.cs_sold_time_sk = t.t_time_sk
    GROUP BY t.t_hour, t.t_minute
),
returns_by_time AS (
    SELECT
        t.t_hour AS hour,
        t.t_minute AS minute,
        SUM(wr.wr_return_amt) AS total_return_amount,
        SUM(wr.wr_net_loss) AS total_return_loss,
        COUNT(*) AS return_transactions
    FROM web_returns wr
    JOIN time_dim t
        ON wr.wr_returned_time_sk = t.t_time_sk
    GROUP BY t.t_hour, t.t_minute
)
SELECT
    COALESCE(s.hour, r.hour) AS hour,
    COALESCE(s.minute, r.minute) AS minute,
    s.total_sales_amount,
    s.total_sales_profit,
    r.total_return_amount,
    r.total_return_loss,
    (COALESCE(s.total_sales_profit, 0) - COALESCE(r.total_return_loss, 0)) AS net_profit_after_returns,
    CASE
        WHEN COALESCE(s.sales_transactions, 0) = 0 THEN NULL
        ELSE COALESCE(s.total_sales_profit, 0) / COALESCE(s.sales_transactions, 1)
    END AS avg_profit_per_sale,
    CASE
        WHEN COALESCE(r.return_transactions, 0) = 0 THEN NULL
        ELSE COALESCE(r.total_return_loss, 0) / COALESCE(r.return_transactions, 1)
    END AS avg_loss_per_return
FROM sales_by_time s
FULL OUTER JOIN returns_by_time r
    ON s.hour = r.hour AND s.minute = r.minute
ORDER BY hour, minute
