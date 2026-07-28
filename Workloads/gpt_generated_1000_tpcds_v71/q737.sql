WITH recent_dates AS (
    SELECT d_date_sk,
           d_year
    FROM date_dim
    WHERE d_year IN (2001, 2002)
)
SELECT
    rd.d_year,
    cd.cd_gender,
    SUM(cs.cs_net_profit) AS total_profit,
    CASE WHEN SUM(cs.cs_net_profit) > 100000 THEN 'High' ELSE 'Low' END AS profit_category,
    'Catalog' AS channel
FROM catalog_sales cs
JOIN recent_dates rd ON cs.cs_sold_date_sk = rd.d_date_sk
JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
GROUP BY rd.d_year, cd.cd_gender

UNION ALL

SELECT
    rd.d_year,
    cd.cd_gender,
    SUM(ws.ws_net_profit) AS total_profit,
    CASE WHEN SUM(ws.ws_net_profit) > 100000 THEN 'High' ELSE 'Low' END AS profit_category,
    'Web' AS channel
FROM web_sales ws
JOIN recent_dates rd ON ws.ws_sold_date_sk = rd.d_date_sk
JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
GROUP BY rd.d_year, cd.cd_gender
LIMIT 100
