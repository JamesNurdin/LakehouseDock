WITH catalog_agg AS (
    SELECT
        i_category AS category,
        SUM(cs_net_profit) AS total_net_profit,
        COUNT(DISTINCT cs_order_number) AS order_cnt,
        'catalog' AS source
    FROM catalog_sales
    JOIN item ON catalog_sales.cs_item_sk = item.i_item_sk
    WHERE catalog_sales.cs_ship_date_sk IN (2450875, 2450865)
      AND item.i_brand_id = 10005006
    GROUP BY i_category
),
web_agg AS (
    SELECT
        i_category AS category,
        SUM(ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws_order_number) AS order_cnt,
        'web' AS source
    FROM web_sales
    JOIN item ON web_sales.ws_item_sk = item.i_item_sk
    JOIN web_site ON web_sales.ws_web_site_sk = web_site.web_site_sk
    WHERE web_site.web_city = 'Springfield'
      AND item.i_brand_id = 10005006
    GROUP BY i_category
)
SELECT
    category,
    total_net_profit,
    order_cnt,
    source
FROM catalog_agg
UNION ALL
SELECT
    category,
    total_net_profit,
    order_cnt,
    source
FROM web_agg
ORDER BY total_net_profit DESC
LIMIT 100
