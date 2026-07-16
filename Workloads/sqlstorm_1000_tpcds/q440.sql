WITH ss AS (
    SELECT d.d_year AS sales_year, s.s_state AS region, ss.ss_net_profit AS profit
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    WHERE d.d_year BETWEEN 1999 AND 2002
), cs AS (
    SELECT d.d_year AS sales_year, cc.cc_state AS region, cs.cs_net_profit AS profit
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    WHERE d.d_year BETWEEN 1999 AND 2002
), ws AS (
    SELECT d.d_year AS sales_year, NULL AS region, ws.ws_net_profit AS profit
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 1999 AND 2002
)
SELECT sales_year, region, sum(profit) AS total_profit
FROM (
    SELECT * FROM ss
    UNION ALL
    SELECT * FROM cs
    UNION ALL
    SELECT * FROM ws
) t
GROUP BY sales_year, region
ORDER BY sales_year, region
