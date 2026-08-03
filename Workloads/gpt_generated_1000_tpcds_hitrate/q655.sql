WITH sales_summary AS (
    SELECT
        ss.ss_cdemo_sk,
        d.d_year,
        SUM(ss.ss_net_profit) AS total_profit,
        COUNT(*) AS sales_cnt,
        CASE WHEN SUM(ss.ss_net_profit) > 0 THEN 'POS' ELSE 'NEG' END AS profit_flag
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY ss.ss_cdemo_sk, d.d_year
    HAVING SUM(ss.ss_net_profit) > 1000
),
catalog_customers AS (
    SELECT DISTINCT
        cs.cs_bill_cdemo_sk AS cdemo_sk,
        cs.cs_item_sk
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
),
eligible_customers AS (
    SELECT ss.ss_cdemo_sk AS cdemo_sk
    FROM sales_summary ss
    INTERSECT
    SELECT cc.cdemo_sk
    FROM catalog_customers cc
)
SELECT
    ec.cdemo_sk,
    cs.total_profit,
    cs.sales_cnt,
    cs.profit_flag
FROM eligible_customers ec
JOIN sales_summary cs ON ec.cdemo_sk = cs.ss_cdemo_sk
WHERE NOT EXISTS (
    SELECT 1
    FROM store_returns sr
    JOIN date_dim d2 ON sr.sr_returned_date_sk = d2.d_date_sk
    WHERE sr.sr_cdemo_sk = ec.cdemo_sk
      AND d2.d_year = 2001
)
ORDER BY cs.total_profit DESC
LIMIT 100
