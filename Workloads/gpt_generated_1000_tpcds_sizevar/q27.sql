WITH filtered_items AS (
    SELECT i_item_sk, i_item_id, i_item_desc
    FROM item
    WHERE regexp_like(i_item_desc, '^[A-Z]{3}[0-9]{2}')
),
promo_sales AS (
    SELECT
        i.i_item_id,
        p.p_promo_id,
        d.d_year,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        CONCAT(i.i_item_id, '-', p.p_promo_id) AS promo_item_key
    FROM web_sales ws
    JOIN filtered_items i ON ws.ws_item_sk = i.i_item_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE p.p_promo_name LIKE '%Clearance%'
      AND d.d_year = 2001
    GROUP BY i.i_item_id, p.p_promo_id, d.d_year, CONCAT(i.i_item_id, '-', p.p_promo_id)
)
SELECT
    ps.i_item_id,
    ps.p_promo_id,
    ps.d_year,
    ps.total_sales,
    ps.order_count,
    ps.promo_item_key
FROM promo_sales ps
WHERE ps.i_item_id NOT IN (
    SELECT i2.i_item_id
    FROM item i2
    WHERE i2.i_product_name LIKE '%Special%'
)
ORDER BY ps.total_sales DESC
LIMIT 100
