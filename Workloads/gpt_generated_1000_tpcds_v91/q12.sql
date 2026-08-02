WITH sales_metrics AS (
    SELECT d.d_year AS year,
           d.d_month_seq AS month,
           'sales' AS metric_type,
           SUM(ws.ws_net_paid) AS total_amount,
           SUM(ws.ws_net_profit) AS total_profit,
           COUNT(*) AS transaction_count
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY d.d_year, d.d_month_seq
),
returns_metrics AS (
    SELECT d.d_year AS year,
           d.d_month_seq AS month,
           'returns' AS metric_type,
           SUM(wr.wr_return_amt) AS total_amount,
           SUM(wr.wr_net_loss) AS total_profit,
           COUNT(*) AS transaction_count
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    GROUP BY d.d_year, d.d_month_seq
),
combined_metrics AS (
    SELECT year,
           month,
           metric_type,
           total_amount,
           total_profit,
           transaction_count
    FROM sales_metrics
    UNION ALL
    SELECT year,
           month,
           metric_type,
           total_amount,
           total_profit,
           transaction_count
    FROM returns_metrics
),
small_ship_modes AS (
    SELECT sm_ship_mode_sk,
           sm_type
    FROM ship_mode
    WHERE sm_type IN ('AIR', 'SEA')
)
SELECT cm.year,
       cm.month,
       cm.metric_type,
       cm.total_amount,
       cm.total_profit,
       cm.transaction_count,
       ssm.sm_type
FROM combined_metrics cm
CROSS JOIN small_ship_modes ssm
WHERE cm.year = 2002
ORDER BY cm.year DESC,
         cm.month,
         cm.metric_type,
         ssm.sm_type
LIMIT 100
