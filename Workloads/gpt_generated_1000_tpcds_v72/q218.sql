WITH high_price_items AS (
    SELECT i_item_sk, i_category
    FROM item
    WHERE i_current_price > 50
)
SELECT
    i.i_item_sk AS item_sk,
    i.i_product_name AS product_name,
    'Return' AS metric_type,
    SUM(cr.cr_return_amount) AS total_amount,
    COUNT(*) AS total_cnt,
    CASE WHEN SUM(cr.cr_return_amount) > 1000 THEN 'High' ELSE 'Low' END AS amount_level,
    (
        SELECT AVG(i2.i_current_price)
        FROM item i2
        WHERE i2.i_category = i.i_category
    ) AS avg_category_price
FROM catalog_returns cr
JOIN item i ON cr.cr_item_sk = i.i_item_sk
JOIN high_price_items hpi ON i.i_item_sk = hpi.i_item_sk
JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
WHERE cd.cd_gender = 'F'
  AND EXISTS (
        SELECT 1
        FROM promotion p
        WHERE p.p_item_sk = i.i_item_sk
          AND p.p_discount_active = 'Y'
    )
GROUP BY i.i_item_sk, i.i_product_name, i.i_category

UNION ALL

SELECT
    ws.ws_item_sk AS item_sk,
    i.i_product_name AS product_name,
    'Sales' AS metric_type,
    SUM(ws.ws_ext_sales_price) AS total_amount,
    COUNT(*) AS total_cnt,
    CASE WHEN SUM(ws.ws_ext_sales_price) > 5000 THEN 'High' ELSE 'Low' END AS amount_level,
    (
        SELECT AVG(i2.i_current_price)
        FROM item i2
        WHERE i2.i_category = i.i_category
    ) AS avg_category_price
FROM web_sales ws
JOIN item i ON ws.ws_item_sk = i.i_item_sk
JOIN high_price_items hpi ON i.i_item_sk = hpi.i_item_sk
JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
WHERE cd.cd_gender = 'F'
  AND EXISTS (
        SELECT 1
        FROM promotion p
        WHERE p.p_item_sk = i.i_item_sk
          AND p.p_discount_active = 'Y'
    )
GROUP BY ws.ws_item_sk, i.i_product_name, i.i_category

ORDER BY total_amount DESC
LIMIT 100
