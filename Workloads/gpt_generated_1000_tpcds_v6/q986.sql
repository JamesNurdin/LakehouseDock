WITH catalog_sales_agg AS (
    SELECT
        i.i_item_id,
        i.i_product_name,
        'catalog' AS sales_channel,
        SUM(cs.cs_quantity) AS total_quantity,
        SUM(cs.cs_net_profit) AS total_profit
    FROM catalog_sales cs
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    LEFT JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    WHERE cs.cs_sold_date_sk BETWEEN 2451000 AND 2451100
      AND cp.cp_department = 'Books'
      AND (p.p_discount_active = 'Y' OR p.p_discount_active IS NULL)
    GROUP BY i.i_item_id, i.i_product_name
),
web_sales_agg AS (
    SELECT
        i.i_item_id,
        i.i_product_name,
        'web' AS sales_channel,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit
    FROM web_sales ws
    JOIN item i
        ON ws.ws_item_sk = i.i_item_sk
    JOIN web_site wsit
        ON ws.ws_web_site_sk = wsit.web_site_sk
    LEFT JOIN promotion p
        ON ws.ws_promo_sk = p.p_promo_sk
    WHERE ws.ws_sold_date_sk BETWEEN 2451000 AND 2451100
      AND wsit.web_class = 'A'
      AND (p.p_discount_active = 'Y' OR p.p_discount_active IS NULL)
    GROUP BY i.i_item_id, i.i_product_name
)
SELECT *
FROM catalog_sales_agg
UNION ALL
SELECT *
FROM web_sales_agg
ORDER BY total_profit DESC
LIMIT 100
