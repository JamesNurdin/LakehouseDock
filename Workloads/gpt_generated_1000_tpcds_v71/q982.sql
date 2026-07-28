WITH catalog_ret AS (
        SELECT cr_item_sk,
               SUM(cr_return_amount) AS catalog_ret_amount,
               SUM(cr_return_quantity) AS catalog_ret_qty
        FROM catalog_returns
        GROUP BY cr_item_sk
    ),
    web_ret AS (
        SELECT wr_item_sk,
               SUM(wr_return_amt) AS web_ret_amount,
               SUM(wr_return_quantity) AS web_ret_qty
        FROM web_returns
        GROUP BY wr_item_sk
    ),
    inventory_agg AS (
        SELECT inv_item_sk,
               SUM(inv_quantity_on_hand) AS inv_quantity_on_hand
        FROM inventory
        GROUP BY inv_item_sk
    ),
    item_agg AS (
        SELECT i.i_item_sk,
               i.i_item_id,
               i.i_item_desc,
               i.i_brand,
               i.i_category,
               i.i_current_price,
               regexp_extract(i.i_item_desc, '(\\d+)$', 1) AS desc_trailing_number,
               i.i_brand || '_' || i.i_category AS brand_category
        FROM item i
        WHERE regexp_like(i.i_item_desc, '[A-Za-z]{3}[0-9]{2}$')
    )
SELECT
    ia.i_item_id,
    ia.i_item_desc,
    ia.brand_category,
    ia.desc_trailing_number,
    COALESCE(cr.catalog_ret_amount, 0) + COALESCE(wr.web_ret_amount, 0) AS total_return_amount,
    COALESCE(cr.catalog_ret_qty, 0) + COALESCE(wr.web_ret_qty, 0) AS total_return_qty,
    inv.inv_quantity_on_hand,
    p.p_promo_name
FROM item_agg ia
LEFT JOIN catalog_ret cr ON cr.cr_item_sk = ia.i_item_sk
LEFT JOIN web_ret wr ON wr.wr_item_sk = ia.i_item_sk
JOIN inventory_agg inv ON inv.inv_item_sk = ia.i_item_sk
JOIN promotion p ON p.p_item_sk = ia.i_item_sk
WHERE inv.inv_quantity_on_hand > 100
  AND p.p_promo_name LIKE '%Discount%'
  AND p.p_channel_demo = 'N'
  AND regexp_like(p.p_promo_name, '^.*(Season|Clearance).*$')
ORDER BY total_return_amount DESC
LIMIT 100
