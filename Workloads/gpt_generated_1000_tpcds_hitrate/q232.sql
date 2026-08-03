/*
Goal: Compare hourly sales performance with hourly web return activity, showing total monetary amounts and distinct customer counts per hour. The query uses a UNION to deduplicate results, includes CASE expressions for profit/loss labeling, and applies an anti‑semi‑join to exclude sales that have a corresponding large return.
*/
WITH sales_agg AS (
    SELECT
        td.t_hour AS period_hour,
        'Sale' AS metric_type,
        SUM(cs.cs_net_paid) AS total_amount,
        COUNT(DISTINCT cs.cs_bill_customer_sk) AS distinct_customers,
        CASE WHEN SUM(cs.cs_net_profit) > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_flag
    FROM catalog_sales cs
    JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    WHERE cd.cd_gender = 'M'
      AND cs.cs_order_number NOT IN (
          SELECT wr.wr_order_number
          FROM web_returns wr
          WHERE wr.wr_return_amt > 500
      )
    GROUP BY td.t_hour
)
SELECT
    period_hour,
    metric_type,
    total_amount,
    distinct_customers,
    profit_flag
FROM sales_agg

UNION

SELECT
    td.t_hour AS period_hour,
    'Return' AS metric_type,
    SUM(wr.wr_return_amt_inc_tax) AS total_amount,
    COUNT(DISTINCT wr.wr_returning_cdemo_sk) AS distinct_customers,
    CASE WHEN SUM(wr.wr_net_loss) > 0 THEN 'Loss' ELSE 'Gain' END AS profit_flag
FROM web_returns wr
JOIN time_dim td ON wr.wr_returned_time_sk = td.t_time_sk
JOIN customer_demographics cd ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
WHERE cd.cd_gender = 'F'
GROUP BY td.t_hour

ORDER BY metric_type, period_hour
LIMIT 100
