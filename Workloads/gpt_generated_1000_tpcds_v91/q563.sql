WITH high_price_items AS (
    SELECT i_item_sk, i_product_name, i_current_price
    FROM item
    WHERE i_current_price > 300
)
SELECT
    order_number,
    item_id,
    product_name,
    quantity,
    net_paid,
    total_returns_amount,
    sales_channel
FROM (
    SELECT
        cs.cs_order_number AS order_number,
        i.i_item_id AS item_id,
        i.i_product_name AS product_name,
        cs.cs_quantity AS quantity,
        cs.cs_net_paid AS net_paid,
        (
            SELECT COALESCE(SUM(cr.cr_return_amount), 0)
            FROM catalog_returns cr
            WHERE cr.cr_item_sk = cs.cs_item_sk
              AND cr.cr_order_number = cs.cs_order_number
        ) AS total_returns_amount,
        'Catalog' AS sales_channel
    FROM catalog_sales cs
    INNER JOIN high_price_items hpi
        ON cs.cs_item_sk = hpi.i_item_sk
    INNER JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    INNER JOIN time_dim t
        ON cs.cs_sold_time_sk = t.t_time_sk
    LEFT JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    WHERE t.t_hour BETWEEN 8 AND 18
      AND EXISTS (
            SELECT 1
            FROM promotion p2
            WHERE p2.p_promo_sk = cs.cs_promo_sk
              AND p2.p_discount_active = 'Y'
        )
) AS catalog_part
UNION ALL
SELECT
    order_number,
    item_id,
    product_name,
    quantity,
    net_paid,
    total_returns_amount,
    sales_channel
FROM (
    SELECT
        ws.ws_order_number AS order_number,
        i.i_item_id AS item_id,
        i.i_product_name AS product_name,
        ws.ws_quantity AS quantity,
        ws.ws_net_paid AS net_paid,
        (
            SELECT COALESCE(SUM(cr.cr_return_amount), 0)
            FROM catalog_returns cr
            WHERE cr.cr_item_sk = ws.ws_item_sk
              AND cr.cr_order_number = ws.ws_order_number
        ) AS total_returns_amount,
        'Web' AS sales_channel
    FROM web_sales ws
    INNER JOIN high_price_items hpi
        ON ws.ws_item_sk = hpi.i_item_sk
    INNER JOIN item i
        ON ws.ws_item_sk = i.i_item_sk
    INNER JOIN time_dim t
        ON ws.ws_sold_time_sk = t.t_time_sk
    LEFT JOIN promotion p
        ON ws.ws_promo_sk = p.p_promo_sk
    WHERE t.t_hour BETWEEN 8 AND 18
      AND EXISTS (
            SELECT 1
            FROM promotion p2
            WHERE p2.p_promo_sk = ws.ws_promo_sk
              AND p2.p_discount_active = 'Y'
        )
) AS web_part
ORDER BY net_paid DESC
LIMIT 100
