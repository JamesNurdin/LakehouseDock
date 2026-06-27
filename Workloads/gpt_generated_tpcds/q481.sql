WITH unified_events AS (
    SELECT cs.cs_sold_date_sk AS date_sk,
           cs.cs_bill_cdemo_sk AS cd_demo_sk,
           cs.cs_net_profit AS net_profit,
           CAST(NULL AS decimal(7,2)) AS net_loss,
           'catalog_sales' AS src
    FROM catalog_sales cs
    UNION ALL
    SELECT cr.cr_returned_date_sk AS date_sk,
           cr.cr_refunded_cdemo_sk AS cd_demo_sk,
           CAST(NULL AS decimal(7,2)) AS net_profit,
           cr.cr_net_loss AS net_loss,
           'catalog_returns' AS src
    FROM catalog_returns cr
    UNION ALL
    SELECT ws.ws_sold_date_sk AS date_sk,
           ws.ws_bill_cdemo_sk AS cd_demo_sk,
           ws.ws_net_profit AS net_profit,
           CAST(NULL AS decimal(7,2)) AS net_loss,
           'web_sales' AS src
    FROM web_sales ws
    UNION ALL
    SELECT wr.wr_returned_date_sk AS date_sk,
           wr.wr_refunded_cdemo_sk AS cd_demo_sk,
           CAST(NULL AS decimal(7,2)) AS net_profit,
           wr.wr_net_loss AS net_loss,
           'web_returns' AS src
    FROM web_returns wr
)
SELECT d.d_year AS year,
       cd.cd_gender,
       cd.cd_marital_status,
       SUM(CASE WHEN ue.src = 'catalog_sales' THEN ue.net_profit ELSE 0 END) AS catalog_sales_profit,
       SUM(CASE WHEN ue.src = 'catalog_returns' THEN ue.net_loss ELSE 0 END) AS catalog_returns_loss,
       SUM(CASE WHEN ue.src = 'web_sales' THEN ue.net_profit ELSE 0 END) AS web_sales_profit,
       SUM(CASE WHEN ue.src = 'web_returns' THEN ue.net_loss ELSE 0 END) AS web_returns_loss,
       SUM(CASE WHEN ue.src IN ('catalog_sales','web_sales') THEN ue.net_profit ELSE 0 END) -
       SUM(CASE WHEN ue.src IN ('catalog_returns','web_returns') THEN ue.net_loss ELSE 0 END) AS net_profit_after_returns
FROM unified_events ue
JOIN date_dim d ON ue.date_sk = d.d_date_sk
JOIN customer_demographics cd ON ue.cd_demo_sk = cd.cd_demo_sk
WHERE d.d_year BETWEEN 2000 AND 2002
GROUP BY d.d_year, cd.cd_gender, cd.cd_marital_status
ORDER BY d.d_year, cd.cd_gender, cd.cd_marital_status
