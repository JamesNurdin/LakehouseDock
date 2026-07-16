WITH sales AS (
    SELECT
        d.d_year AS year,
        p.p_promo_id AS promo_id,
        p.p_promo_name AS promo_name,
        i.i_category AS category,
        i.i_brand AS brand,
        ss.ss_net_paid_inc_tax AS net_paid,
        'store' AS channel
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk

    UNION ALL

    SELECT
        d.d_year,
        p.p_promo_id,
        p.p_promo_name,
        i.i_category,
        i.i_brand,
        cs.cs_net_paid_inc_tax,
        'catalog'
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    LEFT JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk

    UNION ALL

    SELECT
        d.d_year,
        p.p_promo_id,
        p.p_promo_name,
        i.i_category,
        i.i_brand,
        ws.ws_net_paid_inc_tax,
        'web'
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    LEFT JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
)
SELECT
    year,
    promo_id,
    promo_name,
    category,
    brand,
    SUM(CASE WHEN channel = 'store' THEN net_paid ELSE 0 END) AS store_net_paid,
    SUM(CASE WHEN channel = 'catalog' THEN net_paid ELSE 0 END) AS catalog_net_paid,
    SUM(CASE WHEN channel = 'web' THEN net_paid ELSE 0 END) AS web_net_paid,
    SUM(net_paid) AS total_net_paid
FROM sales
WHERE year = 2001
GROUP BY year, promo_id, promo_name, category, brand
ORDER BY total_net_paid DESC
LIMIT 100
