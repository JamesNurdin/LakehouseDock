WITH sales AS (
    SELECT
        d.d_current_week AS week,
        'sales' AS metric_type,
        SUM(ws.ws_net_paid) AS total_amount,
        COUNT(DISTINCT ws.ws_order_number) AS order_cnt
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_purchase_estimate >= 5000
      AND cd.cd_gender = 'F'
    GROUP BY d.d_current_week
),
returns AS (
    SELECT
        d.d_current_week AS week,
        'returns' AS metric_type,
        SUM(wr.wr_net_loss) AS total_amount,
        COUNT(DISTINCT wr.wr_order_number) AS order_cnt
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN customer_demographics cd ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_purchase_estimate < 3000
      AND cd.cd_gender = 'M'
    GROUP BY d.d_current_week
)
SELECT week, metric_type, total_amount, order_cnt
FROM sales
UNION ALL
SELECT week, metric_type, total_amount, order_cnt
FROM returns
ORDER BY week, metric_type
LIMIT 100
