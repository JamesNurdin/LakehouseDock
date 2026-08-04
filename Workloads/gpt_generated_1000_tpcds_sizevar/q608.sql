WITH full_sales_returns AS (
    SELECT
        cs.cs_item_sk,
        cr.cr_item_sk,
        cs.cs_order_number,
        cr.cr_order_number,
        cs.cs_net_paid,
        cr.cr_return_amount,
        cs.cs_sold_date_sk,
        cr.cr_returned_date_sk
    FROM catalog_sales cs
    FULL OUTER JOIN catalog_returns cr
        ON cs.cs_order_number = cr.cr_order_number
),
intersect_items AS (
    SELECT i.i_item_sk
    FROM item i
    WHERE regexp_like(i.i_color, 'pink|purple')
    INTERSECT
    SELECT ws.ws_item_sk
    FROM web_sales ws
    WHERE ws.ws_ext_sales_price > 1000
)
SELECT
    i.i_item_id,
    i.i_color,
    CONCAT(i.i_item_id, '-', i.i_color) AS item_color_key,
    COALESCE(fr.cs_net_paid, 0) - COALESCE(fr.cr_return_amount, 0) AS net_amount,
    LAG(COALESCE(fr.cs_net_paid, 0)) OVER (
        PARTITION BY COALESCE(fr.cs_item_sk, fr.cr_item_sk)
        ORDER BY COALESCE(fr.cs_sold_date_sk, fr.cr_returned_date_sk)
    ) AS prev_net_paid,
    (
        SELECT SUM(ss2.ss_quantity)
        FROM store_sales ss2
        WHERE ss2.ss_item_sk = i.i_item_sk
    ) AS total_store_qty_corr,
    regexp_extract(i.i_product_name, '(\\w+)', 1) AS first_word_product,
    CASE
        WHEN EXISTS (
            SELECT 1
            FROM inventory inv
            WHERE inv.inv_item_sk = i.i_item_sk
              AND inv.inv_quantity_on_hand > 0
        ) THEN 'InStock' ELSE 'OutOfStock'
    END AS stock_status
FROM full_sales_returns fr
JOIN item i
    ON COALESCE(fr.cs_item_sk, fr.cr_item_sk) = i.i_item_sk
JOIN intersect_items ii
    ON i.i_item_sk = ii.i_item_sk
WHERE i.i_product_name LIKE '%Deluxe%'
  AND regexp_like(i.i_color, '^p')
ORDER BY net_amount DESC
LIMIT 100
