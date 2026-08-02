WITH base AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_ext_sales_price,
        ws.ws_net_profit,
        p.p_promo_id,
        p.p_discount_active,
        p.p_channel_email,
        wp.wp_type,
        wp.wp_image_count,
        wp.wp_rec_start_date,
        wp.wp_rec_end_date,
        ws.ws_wholesale_cost
    FROM web_sales ws
    LEFT JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN promotion p
        ON ws.ws_promo_sk = p.p_promo_sk
    WHERE p.p_discount_active = 'N'                         -- predicate 1
      AND p.p_channel_email = 'Y'                           -- predicate 2
      AND wp.wp_image_count >= 3                           -- predicate 3
      AND wp.wp_rec_start_date >= DATE '2000-01-01'         -- predicate 4
      AND wp.wp_rec_end_date <= DATE '2001-12-31'           -- predicate 5
      AND ws.ws_wholesale_cost > 50                         -- predicate 6
      AND ws.ws_quantity >= 2                               -- predicate 7
      AND ws.ws_ext_sales_price > 100                       -- predicate 8
),

agg_by_promo_type AS (
    SELECT 
        p_promo_id,
        wp_type,
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(ws_net_profit) AS total_profit
    FROM base
    GROUP BY ROLLUP (p_promo_id, wp_type)
),

agg_by_promo_item AS (
    SELECT 
        p_promo_id,
        CAST(ws_item_sk AS VARCHAR) AS category,
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(ws_net_profit) AS total_profit
    FROM base
    GROUP BY p_promo_id, ws_item_sk
),

unioned AS (
    SELECT 
        p_promo_id,
        wp_type AS category,
        total_sales,
        total_profit
    FROM agg_by_promo_type
    UNION ALL
    SELECT 
        p_promo_id,
        category,
        total_sales,
        total_profit
    FROM agg_by_promo_item
),

low_profit AS (
    SELECT DISTINCT p_promo_id
    FROM unioned
    WHERE total_profit < 1000
),

exclude_rows AS (
    SELECT 
        p_promo_id,
        category,
        total_sales,
        total_profit
    FROM unioned
    WHERE p_promo_id IN (SELECT p_promo_id FROM low_profit)
)

SELECT 
    u.p_promo_id,
    u.category,
    u.total_sales,
    u.total_profit,
    ROW_NUMBER() OVER (PARTITION BY u.p_promo_id ORDER BY u.total_sales DESC) AS sales_rank,
    CASE 
        WHEN u.total_profit > 5000 THEN 'HIGH'
        WHEN u.total_profit > 2000 THEN 'MEDIUM'
        ELSE 'LOW'
    END AS profit_category
FROM (
    SELECT * FROM unioned
    EXCEPT
    SELECT * FROM exclude_rows
) AS u
ORDER BY u.total_sales DESC
LIMIT 100
