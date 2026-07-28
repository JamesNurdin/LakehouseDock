WITH catalog_sales_agg AS (
    SELECT
        concat(cc.cc_name, '-', cc.cc_city) AS call_center_desc,
        CASE WHEN cs.cs_net_profit > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_flag,
        sum(cs.cs_net_paid) AS total_net_paid,
        sum(cs.cs_net_profit) AS total_net_profit
    FROM catalog_sales cs
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE regexp_like(i.i_product_name, '(Pro|Max)')
      AND cc.cc_name LIKE 'A%'
    GROUP BY
        concat(cc.cc_name, '-', cc.cc_city),
        CASE WHEN cs.cs_net_profit > 0 THEN 'Profitable' ELSE 'Loss' END
),
web_sales_agg AS (
    SELECT
        concat(wp.wp_type, '_', substring(wp.wp_url, 1, 10)) AS page_desc,
        CASE WHEN sum(ws.ws_net_profit) > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_flag,
        sum(ws.ws_net_paid) AS total_net_paid,
        sum(ws.ws_net_profit) AS total_net_profit
    FROM web_sales ws
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE regexp_like(wp.wp_url, 'sports')
      AND wp.wp_autogen_flag = 'N'
      AND i.i_brand_id = 2004002
    GROUP BY concat(wp.wp_type, '_', substring(wp.wp_url, 1, 10))
)
SELECT *
FROM (
    SELECT
        'Catalog' AS source,
        call_center_desc AS entity,
        profit_flag,
        total_net_paid,
        total_net_profit
    FROM catalog_sales_agg
    UNION ALL
    SELECT
        'Web' AS source,
        page_desc AS entity,
        profit_flag,
        total_net_paid,
        total_net_profit
    FROM web_sales_agg
) combined
ORDER BY total_net_paid DESC
LIMIT 100
