WITH
    -- Sample 10% of the inventory rows to reduce data volume
    inv_sample AS (
        SELECT *
        FROM inventory
        TABLESAMPLE BERNOULLI (10)
    ),
    -- Aggregate inventory per item and warehouse before joining other tables
    inv_agg AS (
        SELECT
            inv_item_sk,
            inv_warehouse_sk,
            SUM(inv_quantity_on_hand) AS total_qty
        FROM inv_sample
        GROUP BY inv_item_sk, inv_warehouse_sk
    ),
    -- Keep only active promotions with a response target of 1 and compute the maximum promo cost per item
    promo_active AS (
        SELECT
            p_item_sk,
            MAX(p_cost) AS max_promo_cost
        FROM promotion
        WHERE p_discount_active = 'Y'
          AND p_response_target = 1
        GROUP BY p_item_sk
    ),
    -- Prepare store‑return‑centric rows
    store_data AS (
        SELECT
            i.i_item_id          AS item_id,
            i.i_brand            AS brand,
            w.w_warehouse_name   AS warehouse_name,
            sr.sr_return_amt     AS store_return_amt,
            sr.sr_return_quantity AS store_return_qty,
            CAST(NULL AS decimal(7,2)) AS web_return_amt,
            CAST(NULL AS integer)     AS web_return_qty,
            cr.cr_return_amount  AS catalog_return_amt,
            cr.cr_return_quantity AS catalog_return_qty,
            i.i_current_price    AS current_price,
            inv_agg.total_qty    AS total_qty,
            promo_active.max_promo_cost AS max_promo_cost,
            (SELECT COUNT(*) FROM promotion p WHERE p.p_item_sk = i.i_item_sk) AS promo_count
        FROM store_returns sr
        JOIN item i ON sr.sr_item_sk = i.i_item_sk
        JOIN store s ON sr.sr_store_sk = s.s_store_sk
        JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
        JOIN inv_agg ON inv_agg.inv_item_sk = i.i_item_sk
        JOIN warehouse w ON inv_agg.inv_warehouse_sk = w.w_warehouse_sk
        LEFT JOIN catalog_returns cr
               ON cr.cr_item_sk = i.i_item_sk
              AND cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
        LEFT JOIN promo_active ON promo_active.p_item_sk = i.i_item_sk
        WHERE i.i_current_price > 20.00
          AND s.s_state = 'CA'
          AND sr.sr_return_ship_cost > 50.00
          AND cr.cr_returned_date_sk BETWEEN 2451500 AND 2452000
    ),
    -- Prepare web‑return‑centric rows (store‑related columns are null)
    web_data AS (
        SELECT
            i.i_item_id          AS item_id,
            i.i_brand            AS brand,
            w.w_warehouse_name   AS warehouse_name,
            CAST(NULL AS decimal(7,2)) AS store_return_amt,
            CAST(NULL AS integer)     AS store_return_qty,
            wr.wr_return_amt     AS web_return_amt,
            wr.wr_return_quantity AS web_return_qty,
            cr.cr_return_amount  AS catalog_return_amt,
            cr.cr_return_quantity AS catalog_return_qty,
            i.i_current_price    AS current_price,
            inv_agg.total_qty    AS total_qty,
            promo_active.max_promo_cost AS max_promo_cost,
            (SELECT COUNT(*) FROM promotion p WHERE p.p_item_sk = i.i_item_sk) AS promo_count
        FROM web_returns wr
        JOIN item i ON wr.wr_item_sk = i.i_item_sk
        JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
        JOIN customer_demographics cd ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
        JOIN inv_agg ON inv_agg.inv_item_sk = i.i_item_sk
        JOIN warehouse w ON inv_agg.inv_warehouse_sk = w.w_warehouse_sk
        LEFT JOIN catalog_returns cr
               ON cr.cr_item_sk = i.i_item_sk
              AND cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
        LEFT JOIN promo_active ON promo_active.p_item_sk = i.i_item_sk
        WHERE i.i_brand = 'Brand#12'
          AND w.w_state = 'CA'
          AND wr.wr_account_credit > 100.00
          AND wr.wr_returned_date_sk BETWEEN 2451500 AND 2452000
    )
SELECT
    item_id,
    brand,
    warehouse_name,
    SUM(COALESCE(store_return_amt, 0) + COALESCE(web_return_amt, 0) + COALESCE(catalog_return_amt, 0)) AS total_return_amount,
    SUM(COALESCE(store_return_qty, 0) + COALESCE(web_return_qty, 0) + COALESCE(catalog_return_qty, 0)) AS total_return_quantity,
    AVG(current_price) AS avg_item_price,
    MAX(max_promo_cost) AS max_promo_cost,
    SUM(total_qty) AS total_inventory_qty,
    SUM(promo_count) AS total_promo_count
FROM (
    SELECT * FROM store_data
    UNION
    SELECT * FROM web_data
) AS unified
GROUP BY ROLLUP (item_id, brand, warehouse_name)
HAVING SUM(COALESCE(store_return_amt, 0) + COALESCE(web_return_amt, 0) + COALESCE(catalog_return_amt, 0)) > 0
LIMIT 100
