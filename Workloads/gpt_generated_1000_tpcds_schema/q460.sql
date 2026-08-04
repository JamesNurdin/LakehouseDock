WITH
    catalog_sample AS (
        SELECT cs.cs_item_sk,
               cs.cs_quantity,
               cs.cs_ext_sales_price,
               cs.cs_net_profit,
               cs.cs_catalog_page_sk,
               cs.cs_promo_sk
        FROM catalog_sales cs
        TABLESAMPLE BERNOULLI (10)
        WHERE cs.cs_quantity > 0
    ),
    web_sample AS (
        SELECT ws.ws_item_sk,
               ws.ws_quantity,
               ws.ws_ext_sales_price,
               ws.ws_net_profit,
               ws.ws_web_site_sk,
               ws.ws_promo_sk
        FROM web_sales ws
        TABLESAMPLE BERNOULLI (10)
        WHERE ws.ws_quantity > 0
    ),
    catalog_agg AS (
        SELECT
            cp.cp_department AS department,
            p.p_channel_dmail AS promo_channel,
            SUM(cs.cs_ext_sales_price) AS total_sales,
            SUM(cs.cs_net_profit) AS total_profit,
            'Catalog' AS source
        FROM catalog_sample cs
        JOIN item i ON cs.cs_item_sk = i.i_item_sk
        JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
        JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
        GROUP BY ROLLUP (cp.cp_department, p.p_channel_dmail)
    ),
    web_agg AS (
        SELECT
            i.i_category AS department,
            p.p_channel_dmail AS promo_channel,
            SUM(ws.ws_ext_sales_price) AS total_sales,
            SUM(ws.ws_net_profit) AS total_profit,
            'Web' AS source
        FROM web_sample ws
        JOIN item i ON ws.ws_item_sk = i.i_item_sk
        JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
        GROUP BY ROLLUP (i.i_category, p.p_channel_dmail)
    ),
    catalog_items AS (
        SELECT DISTINCT cs.cs_item_sk
        FROM catalog_sales cs
    ),
    web_items AS (
        SELECT DISTINCT ws.ws_item_sk
        FROM web_sales ws
    ),
    catalog_only_items AS (
        SELECT ci.cs_item_sk
        FROM catalog_items ci
        EXCEPT
        SELECT wi.ws_item_sk
        FROM web_items wi
    )
SELECT
    department,
    promo_channel,
    total_sales,
    total_profit,
    source
FROM (
    SELECT department, promo_channel, total_sales, total_profit, source
    FROM catalog_agg
    UNION
    SELECT department, promo_channel, total_sales, total_profit, source
    FROM web_agg
) AS combined
ORDER BY department ASC, total_sales DESC
OFFSET 0 LIMIT 100
