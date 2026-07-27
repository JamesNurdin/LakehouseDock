WITH sales AS (
    SELECT
        td.t_hour,
        td.t_minute,
        'sales' AS source,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_net_profit) AS total_metric,
        'profit' AS metric,
        CASE WHEN td.t_hour >= 12 THEN 'Peak' ELSE 'Off-Peak' END AS period
    FROM catalog_sales cs
    JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    WHERE i.i_category = 'Sports'
      AND cd.cd_marital_status = 'M'
    GROUP BY td.t_hour,
        td.t_minute,
        CASE WHEN td.t_hour >= 12 THEN 'Peak' ELSE 'Off-Peak' END
),
returns AS (
    SELECT
        td.t_hour,
        td.t_minute,
        'returns' AS source,
        SUM(wr.wr_return_amt) AS total_sales,
        SUM(wr.wr_net_loss) AS total_metric,
        'loss' AS metric,
        CASE WHEN td.t_hour >= 12 THEN 'Peak' ELSE 'Off-Peak' END AS period
    FROM web_returns wr
    JOIN time_dim td ON wr.wr_returned_time_sk = td.t_time_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    JOIN customer_demographics cd ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
    WHERE i.i_category = 'Sports'
      AND cd.cd_marital_status = 'M'
    GROUP BY td.t_hour,
        td.t_minute,
        CASE WHEN td.t_hour >= 12 THEN 'Peak' ELSE 'Off-Peak' END
)
SELECT
    t_hour,
    t_minute,
    source,
    period,
    total_sales,
    total_metric,
    metric
FROM sales
UNION ALL
SELECT
    t_hour,
    t_minute,
    source,
    period,
    total_sales,
    total_metric,
    metric
FROM returns
ORDER BY t_hour, t_minute, source
