WITH
    inv_join AS (
        SELECT i.inv_warehouse_sk,
               i.inv_item_sk,
               i.inv_quantity_on_hand,
               d.d_date,
               d.d_year,
               d.d_week_seq
        FROM inventory i
        JOIN date_dim d
          ON i.inv_date_sk = d.d_date_sk
        WHERE d.d_date >= DATE '2001-01-01'
          AND d.d_date < DATE '2002-01-01'
    ),
    catalog_filtered AS (
        SELECT cp.cp_catalog_page_sk,
               cp.cp_description,
               d_start.d_date AS start_date,
               d_end.d_date   AS end_date
        FROM catalog_page cp
        JOIN date_dim d_start
          ON cp.cp_start_date_sk = d_start.d_date_sk
        JOIN date_dim d_end
          ON cp.cp_end_date_sk = d_end.d_date_sk
        WHERE cp.cp_description LIKE '%sale%'
          AND regexp_like(cp.cp_description, '(?i)new')
    ),
    item_set_a AS (
        SELECT inv_item_sk FROM inventory WHERE inv_quantity_on_hand > 500
    ),
    item_set_b AS (
        SELECT inv_item_sk FROM inventory WHERE inv_quantity_on_hand < 200
    ),
    items_except AS (
        SELECT inv_item_sk FROM item_set_a
        EXCEPT
        SELECT inv_item_sk FROM item_set_b
    ),
    items_intersect AS (
        SELECT inv_item_sk FROM item_set_a
        INTERSECT
        SELECT inv_item_sk FROM item_set_b
    ),
    final AS (
        SELECT
            i.inv_warehouse_sk,
            i.inv_item_sk,
            i.inv_quantity_on_hand,
            i.d_date,
            i.d_year,
            i.d_week_seq,
            rank() OVER (PARTITION BY i.inv_warehouse_sk ORDER BY i.inv_quantity_on_hand DESC) AS qty_rank,
            (
                SELECT sum(i2.inv_quantity_on_hand)
                FROM inventory i2
                WHERE i2.inv_warehouse_sk = i.inv_warehouse_sk
            ) AS total_qty_warehouse,
            regexp_extract(cf.cp_description, '(sale|discount)', 1) AS promo_word,
            substring(cf.cp_description FROM 1 FOR 20) AS desc_prefix,
            (
                SELECT concat(cc.cc_city, ', ', cc.cc_state)
                FROM call_center cc
                WHERE regexp_like(cc.cc_street_type, 'Road')
                LIMIT 1
            ) AS sample_cc_location,
            CASE WHEN i.inv_item_sk IN (SELECT inv_item_sk FROM items_except) THEN 1 ELSE 0 END AS in_except,
            CASE WHEN i.inv_item_sk IN (SELECT inv_item_sk FROM items_intersect) THEN 1 ELSE 0 END AS in_intersect
        FROM inv_join i
        LEFT JOIN catalog_filtered cf
          ON i.d_date BETWEEN cf.start_date AND cf.end_date
        WHERE regexp_like(CAST(i.inv_quantity_on_hand AS VARCHAR), '^[0-9]{3}$')
    )
SELECT *
FROM final
ORDER BY inv_warehouse_sk, qty_rank
LIMIT 100
