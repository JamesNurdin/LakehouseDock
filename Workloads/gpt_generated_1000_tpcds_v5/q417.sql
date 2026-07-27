WITH catalog_sales_agg AS (
    SELECT
        d.d_date,
        'Catalog' AS sales_channel,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        CASE WHEN SUM(cs.cs_net_profit) > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_category
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    WHERE cc.cc_market_manager = 'John Miller'
      AND d.d_year = 2001
    GROUP BY d.d_date
),
web_sales_agg AS (
    SELECT
        d.d_date,
        'Web' AS sales_channel,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        CASE WHEN SUM(ws.ws_net_profit) > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_category
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND ws.ws_quantity > 10
    GROUP BY d.d_date
)
SELECT
    c.d_date,
    c.sales_channel,
    c.total_sales,
    c.profit_category
FROM catalog_sales_agg c
UNION ALL
SELECT
    w.d_date,
    w.sales_channel,
    w.total_sales,
    w.profit_category
FROM web_sales_agg w
LIMIT 100
