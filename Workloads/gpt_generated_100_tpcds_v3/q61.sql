WITH filtered_items AS (
    SELECT
        i.i_item_sk,
        i.i_product_name,
        i.i_brand,
        i.i_class,
        i.i_color,
        regexp_extract(i.i_product_name, '(\\d+)', 1) AS product_code,
        concat(i.i_brand, ' - ', i.i_product_name) AS brand_product
    FROM item i
    WHERE regexp_like(i.i_product_name, '^[A-Z]{3}[0-9]{2}')
),

promo_filtered AS (
    SELECT
        p.p_promo_sk,
        p.p_promo_name
    FROM promotion p
    WHERE p.p_promo_name LIKE '%Discount%'
),

catalog_agg AS (
    SELECT
        fi.i_item_sk,
        pf.p_promo_sk,
        sum(cs.cs_net_profit) AS catalog_net_profit
    FROM catalog_sales cs
    JOIN filtered_items fi ON cs.cs_item_sk = fi.i_item_sk
    JOIN promo_filtered pf ON cs.cs_promo_sk = pf.p_promo_sk
    GROUP BY fi.i_item_sk, pf.p_promo_sk
),

web_agg AS (
    SELECT
        fi.i_item_sk,
        pf.p_promo_sk,
        sum(ws.ws_net_profit) AS web_net_profit
    FROM web_sales ws
    JOIN filtered_items fi ON ws.ws_item_sk = fi.i_item_sk
    JOIN promo_filtered pf ON ws.ws_promo_sk = pf.p_promo_sk
    GROUP BY fi.i_item_sk, pf.p_promo_sk
),

returns_agg AS (
    SELECT
        fi.i_item_sk,
        count(DISTINCT s.s_store_name) AS distinct_return_stores
    FROM store_returns sr
    JOIN filtered_items fi ON sr.sr_item_sk = fi.i_item_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    GROUP BY fi.i_item_sk
)

SELECT
    fi.brand_product,
    pf.p_promo_name,
    coalesce(ca.catalog_net_profit, 0) + coalesce(wa.web_net_profit, 0) AS total_net_profit,
    ra.distinct_return_stores
FROM filtered_items fi
JOIN catalog_agg ca ON ca.i_item_sk = fi.i_item_sk
JOIN promo_filtered pf ON pf.p_promo_sk = ca.p_promo_sk
LEFT JOIN web_agg wa ON wa.i_item_sk = fi.i_item_sk AND wa.p_promo_sk = pf.p_promo_sk
LEFT JOIN returns_agg ra ON ra.i_item_sk = fi.i_item_sk
WHERE (coalesce(ca.catalog_net_profit, 0) + coalesce(wa.web_net_profit, 0)) > 0
ORDER BY total_net_profit DESC
LIMIT 100
