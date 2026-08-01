WITH
    sampled_inventory AS (
        SELECT inv_item_sk,
               inv_quantity_on_hand
        FROM inventory TABLESAMPLE BERNOULLI (10)
    ),
    item_promo_full AS (
        SELECT i.i_item_sk,
               i.i_item_id,
               i.i_item_desc,
               p.p_promo_name,
               p.p_discount_active
        FROM item i
        FULL OUTER JOIN promotion p
          ON p.p_item_sk = i.i_item_sk
    ),
    intersect_items AS (
        SELECT i.i_item_id
        FROM store_returns sr
        JOIN item i ON sr.sr_item_sk = i.i_item_sk
        WHERE sr.sr_return_quantity > 1
        INTERSECT
        SELECT i2.i_item_id
        FROM catalog_returns cr
        JOIN item i2 ON cr.cr_item_sk = i2.i_item_sk
        WHERE cr.cr_return_quantity > 1
    ),
    first_set AS (
        SELECT ipf.i_item_id,
               ipf.i_item_desc,
               ipf.p_promo_name,
               ipf.p_discount_active,
               (
                   SELECT COUNT(*)
                   FROM sampled_inventory inv
                   WHERE inv.inv_item_sk = ipf.i_item_sk
               ) AS sampled_inv_cnt
        FROM item_promo_full ipf
        WHERE ipf.i_item_id IN (SELECT i_item_id FROM intersect_items)
          AND EXISTS (
              SELECT 1
              FROM sampled_inventory inv
              WHERE inv.inv_item_sk = ipf.i_item_sk
          )
    ),
    second_set AS (
        SELECT i.i_item_id,
               i.i_item_desc,
               NULL AS p_promo_name,
               NULL AS p_discount_active,
               0 AS sampled_inv_cnt
        FROM item i
        WHERE i.i_item_id NOT IN (SELECT i_item_id FROM intersect_items)
          AND i.i_current_price > 100
    )
SELECT *
FROM first_set
UNION ALL
SELECT *
FROM second_set
ORDER BY i_item_id
LIMIT 200
