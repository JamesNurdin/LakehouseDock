/* Goal: Compare total net paid revenue for married customers during the first shift across catalog sales and store sales. */
WITH catalog_sales_summary AS (
    SELECT
        td.t_shift AS shift,
        'catalog' AS sales_channel,
        SUM(cs.cs_net_paid) AS total_net_paid
    FROM tpcds.catalog_sales cs
    JOIN tpcds.time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN tpcds.customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    WHERE td.t_shift = 'first'
      AND cd.cd_marital_status = 'M'
    GROUP BY td.t_shift
),
store_sales_summary AS (
    SELECT
        td.t_shift AS shift,
        'store' AS sales_channel,
        SUM(ss.ss_net_paid) AS total_net_paid
    FROM tpcds.store_sales ss
    JOIN tpcds.time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN tpcds.customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    WHERE td.t_shift = 'first'
      AND cd.cd_marital_status = 'M'
    GROUP BY td.t_shift
)
SELECT shift, sales_channel, total_net_paid
FROM catalog_sales_summary
UNION ALL
SELECT shift, sales_channel, total_net_paid
FROM store_sales_summary
ORDER BY sales_channel
