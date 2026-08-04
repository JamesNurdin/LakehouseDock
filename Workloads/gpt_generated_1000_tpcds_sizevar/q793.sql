WITH
sampled_inventory AS (
    SELECT *
    FROM inventory
    TABLESAMPLE BERNOULLI (10)
),
cat_dim AS (
    SELECT
        cs.cs_order_number,
        cs.cs_item_sk,
        cs.cs_net_paid_inc_tax,
        i_c.i_product_name,
        p_c.p_promo_name,
        sm_c.sm_type
    FROM catalog_sales cs
    JOIN item i_c ON cs.cs_item_sk = i_c.i_item_sk
    JOIN promotion p_c ON cs.cs_promo_sk = p_c.p_promo_sk
    JOIN ship_mode sm_c ON cs.cs_ship_mode_sk = sm_c.sm_ship_mode_sk
),
web_dim AS (
    SELECT
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_net_paid_inc_tax,
        i_w.i_product_name,
        p_w.p_promo_name,
        sm_w.sm_type,
        wp.wp_type
    FROM web_sales ws
    JOIN item i_w ON ws.ws_item_sk = i_w.i_item_sk
    JOIN promotion p_w ON ws.ws_promo_sk = p_w.p_promo_sk
    JOIN ship_mode sm_w ON ws.ws_ship_mode_sk = sm_w.sm_ship_mode_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
),
combined AS (
    SELECT
        cs_order_number AS order_number,
        cs_item_sk AS item_sk,
        i_product_name AS product_name,
        p_promo_name AS promo_name,
        sm_type AS ship_type,
        cs_net_paid_inc_tax AS net_paid,
        'catalog' AS source
    FROM cat_dim
    UNION
    SELECT
        ws_order_number,
        ws_item_sk,
        i_product_name,
        p_promo_name,
        sm_type,
        ws_net_paid_inc_tax,
        'web' AS source
    FROM web_dim
),
order_exclusive AS (
    SELECT cs_order_number AS order_number
    FROM catalog_sales
    EXCEPT
    SELECT ws_order_number
    FROM web_sales
),
web_sales_no_page AS (
    SELECT
        ws_order_number,
        ws_item_sk,
        ws_web_page_sk
    FROM web_sales
),
full_wp AS (
    SELECT *
    FROM web_sales_no_page wsnp
    FULL OUTER JOIN web_page wp
        ON wsnp.ws_web_page_sk = wp.wp_web_page_sk
)
SELECT
    c.order_number,
    c.item_sk,
    c.product_name,
    c.promo_name,
    c.ship_type,
    c.net_paid,
    c.source,
    (oe.order_number IS NOT NULL) AS exclusive_to_catalog,
    inv.inv_quantity_on_hand,
    sr.sr_return_quantity,
    wr.wr_return_quantity,
    fw.wp_type,
    ROW_NUMBER() OVER (ORDER BY c.net_paid DESC) AS row_num
FROM combined c
LEFT JOIN order_exclusive oe
    ON c.order_number = oe.order_number
LEFT JOIN sampled_inventory inv
    ON c.item_sk = inv.inv_item_sk
LEFT JOIN store_returns sr
    ON sr.sr_item_sk = c.item_sk
LEFT JOIN web_returns wr
    ON wr.wr_item_sk = c.item_sk AND wr.wr_order_number = c.order_number
LEFT JOIN full_wp fw
    ON c.order_number = fw.ws_order_number
ORDER BY row_num
LIMIT 100
