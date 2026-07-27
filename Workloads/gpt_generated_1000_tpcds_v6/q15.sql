WITH store_agg AS (
    SELECT
        i.i_item_id AS item_id,
        i.i_product_name AS product_name,
        i.i_class AS item_class,
        SUM(ss.ss_ext_sales_price) AS sales_amount,
        'store' AS sales_channel
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    WHERE i.i_class = 'shirts'
      AND p.p_discount_active = 'Y'
      AND c.c_birth_month = 11
    GROUP BY i.i_item_id, i.i_product_name, i.i_class
),
web_agg AS (
    SELECT
        i.i_item_id AS item_id,
        i.i_product_name AS product_name,
        i.i_class AS item_class,
        SUM(ws.ws_ext_sales_price) AS sales_amount,
        'web' AS sales_channel
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    WHERE i.i_class = 'shirts'
      AND p.p_discount_active = 'Y'
      AND c.c_birth_month = 11
    GROUP BY i.i_item_id, i.i_product_name, i.i_class
)
SELECT *
FROM store_agg
UNION ALL
SELECT *
FROM web_agg
ORDER BY sales_amount DESC
LIMIT 100
