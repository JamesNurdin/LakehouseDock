/*
Goal: Compare yearly net profit and net paid amounts for catalog and web sales channels, categorizing profit as 'Profit' or 'Loss', and retain only high‑profit years/entities.
*/
WITH catalog_agg AS (
    SELECT
        d.d_year AS year,
        'Catalog' AS channel,
        cc.cc_name AS entity,
        SUM(cs.cs_net_profit) AS total_net_profit,
        SUM(cs.cs_net_paid) AS total_net_paid,
        CASE WHEN SUM(cs.cs_net_profit) >= 0 THEN 'Profit' ELSE 'Loss' END AS profit_flag
    FROM
        catalog_sales cs
        JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
        JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    WHERE
        d.d_year BETWEEN 2000 AND 2002
        AND cs.cs_quantity > 0
    GROUP BY
        d.d_year,
        cc.cc_name
    HAVING
        SUM(cs.cs_net_profit) > 10000
),
web_agg AS (
    SELECT
        d.d_year AS year,
        'Web' AS channel,
        CAST(ws.ws_web_page_sk AS varchar) AS entity,
        SUM(ws.ws_net_profit) AS total_net_profit,
        SUM(ws.ws_net_paid) AS total_net_paid,
        CASE WHEN SUM(ws.ws_net_profit) >= 0 THEN 'Profit' ELSE 'Loss' END AS profit_flag
    FROM
        web_sales ws
        JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE
        d.d_year BETWEEN 2000 AND 2002
        AND ws.ws_quantity > 0
    GROUP BY
        d.d_year,
        ws.ws_web_page_sk
    HAVING
        SUM(ws.ws_net_profit) > 5000
)
SELECT DISTINCT
    combined.year,
    combined.channel,
    combined.entity,
    combined.total_net_profit,
    combined.total_net_paid,
    combined.profit_flag
FROM (
    SELECT
        ca.year,
        ca.channel,
        ca.entity,
        ca.total_net_profit,
        ca.total_net_paid,
        ca.profit_flag
    FROM catalog_agg ca
    UNION ALL
    SELECT
        wa.year,
        wa.channel,
        wa.entity,
        wa.total_net_profit,
        wa.total_net_paid,
        wa.profit_flag
    FROM web_agg wa
) AS combined
ORDER BY
    combined.year DESC,
    combined.total_net_profit DESC
LIMIT 100
