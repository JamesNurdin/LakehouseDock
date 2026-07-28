WITH web_sales_agg AS (
    SELECT
        ws_item_sk,
        SUM(ws_net_paid) AS web_net_paid,
        COUNT(*) AS web_orders
    FROM web_sales
    WHERE ws_sales_price > 20
    GROUP BY ws_item_sk
)
SELECT
    i.i_item_sk,
    i.i_item_id,
    i.i_product_name,
    SUBSTRING(i.i_product_name, 1, 10) AS short_name,
    COUNT(*) AS catalog_orders,
    SUM(cs.cs_net_paid) AS catalog_net_paid,
    wa.web_net_paid,
    wa.web_orders,
    (SELECT MAX(p_cost) FROM promotion WHERE p_item_sk = i.i_item_sk) AS max_promo_cost
FROM catalog_sales cs
JOIN item i
    ON cs.cs_item_sk = i.i_item_sk
JOIN customer c
    ON cs.cs_bill_customer_sk = c.c_customer_sk
LEFT JOIN web_sales_agg wa
    ON i.i_item_sk = wa.ws_item_sk
WHERE
    regexp_like(i.i_item_desc, '(?i)digital|wireless')
    AND (c.c_first_name || ' ' || c.c_last_name) LIKE 'A%'
    AND EXISTS (
        SELECT 1
        FROM catalog_returns cr
        WHERE cr.cr_item_sk = i.i_item_sk
          AND cr.cr_net_loss > 100
    )
GROUP BY
    i.i_item_sk,
    i.i_item_id,
    i.i_product_name,
    SUBSTRING(i.i_product_name, 1, 10),
    wa.web_net_paid,
    wa.web_orders
LIMIT 100
