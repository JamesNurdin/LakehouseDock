WITH
    /* Aggregate inventory per item and warehouse */
    inv_agg AS (
        SELECT
            inv_item_sk,
            inv_warehouse_sk,
            SUM(inv_quantity_on_hand) AS total_qty
        FROM inventory
        GROUP BY inv_item_sk, inv_warehouse_sk
    ),
    /* Raw inventory – reused under a different alias */
    inv_raw AS (
        SELECT inv_item_sk, inv_warehouse_sk, inv_quantity_on_hand
        FROM inventory
    ),
    /* Keys from catalog_returns */
    cat_keys AS (
        SELECT cr.cr_order_number AS order_key
        FROM catalog_returns cr
        JOIN customer c               ON cr.cr_refunded_customer_sk = c.c_customer_sk
        JOIN customer_address ca      ON cr.cr_refunded_addr_sk    = ca.ca_address_sk
        JOIN item i                    ON cr.cr_item_sk            = i.i_item_sk
        JOIN warehouse w               ON cr.cr_warehouse_sk       = w.w_warehouse_sk
    ),
    /* Keys from store_returns */
    store_keys AS (
        SELECT sr.sr_ticket_number AS order_key
        FROM store_returns sr
        JOIN store s                 ON sr.sr_store_sk   = s.s_store_sk
        JOIN item i2                 ON sr.sr_item_sk   = i2.i_item_sk
        JOIN time_dim td            ON sr.sr_return_time_sk = td.t_time_sk
    ),
    /* UNION of the two key sets (distinct by default) */
    union_keys AS (
        SELECT order_key FROM cat_keys
        UNION
        SELECT order_key FROM store_keys
    ),
    /* Orders present in catalog_returns but not in store_returns */
    except_keys AS (
        SELECT order_key FROM cat_keys
        EXCEPT
        SELECT order_key FROM store_keys
    ),
    /* Orders present in both catalogs */
    intersect_keys AS (
        SELECT order_key FROM cat_keys
        INTERSECT
        SELECT order_key FROM store_keys
    ),
    /* Aggregation of catalog returns */
    cat_agg AS (
        SELECT
            w.w_warehouse_name      AS warehouse_name,
            i.i_item_id             AS item_id,
            SUM(cr.cr_return_amount) AS return_amount,
            SUM(cr.cr_net_loss)      AS net_loss,
            SUM(cr.cr_return_quantity) AS return_qty
        FROM catalog_returns cr
        JOIN time_dim td          ON cr.cr_returned_time_sk = td.t_time_sk
        JOIN item i               ON cr.cr_item_sk          = i.i_item_sk
        JOIN customer c           ON cr.cr_refunded_customer_sk = c.c_customer_sk
        JOIN customer_address ca ON cr.cr_refunded_addr_sk      = ca.ca_address_sk
        JOIN warehouse w         ON cr.cr_warehouse_sk          = w.w_warehouse_sk
        JOIN inv_agg ia          ON cr.cr_item_sk = ia.inv_item_sk
                                 AND cr.cr_warehouse_sk = ia.inv_warehouse_sk
        GROUP BY w.w_warehouse_name, i.i_item_id
    ),
    /* Aggregation of store returns – uses a FULL OUTER JOIN */
    store_agg AS (
        SELECT
            s.s_store_name          AS store_name,
            i2.i_item_id            AS item_id,
            SUM(sr.sr_return_amt)   AS return_amount,
            SUM(sr.sr_net_loss)     AS net_loss,
            SUM(sr.sr_return_quantity) AS return_qty
        FROM store_returns sr
        FULL OUTER JOIN store s      ON sr.sr_store_sk = s.s_store_sk
        JOIN time_dim td2          ON sr.sr_return_time_sk = td2.t_time_sk
        JOIN item i2               ON sr.sr_item_sk        = i2.i_item_sk
        JOIN customer c2          ON sr.sr_customer_sk    = c2.c_customer_sk
        JOIN customer_address ca2 ON sr.sr_addr_sk        = ca2.ca_address_sk
        JOIN inv_raw ir           ON sr.sr_item_sk = ir.inv_item_sk
        GROUP BY s.s_store_name, i2.i_item_id
    ),
    /* Combine the two aggregations – UNION forces a distinct‑aggregate */
    combined AS (
        SELECT
            warehouse_name,
            NULL AS store_name,
            item_id,
            return_amount,
            net_loss,
            return_qty,
            'catalog' AS source
        FROM cat_agg
        UNION
        SELECT
            NULL AS warehouse_name,
            store_name,
            item_id,
            return_amount,
            net_loss,
            return_qty,
            'store' AS source
        FROM store_agg
    ),
    /* Anti‑semi‑join example – catalog orders not present in store returns */
    anti_catalog AS (
        SELECT DISTINCT cr.cr_order_number
        FROM catalog_returns cr
        WHERE cr.cr_order_number NOT IN (SELECT order_key FROM store_keys)
    )
SELECT DISTINCT
    c.warehouse_name,
    c.store_name,
    c.item_id,
    c.return_amount,
    c.net_loss,
    c.return_qty,
    c.source,
    (SELECT COUNT(*) FROM except_keys)   AS except_key_cnt,
    (SELECT COUNT(*) FROM intersect_keys) AS intersect_key_cnt,
    (SELECT COUNT(*) FROM anti_catalog)   AS anti_key_cnt
FROM combined c
WHERE c.return_amount IS NOT NULL
LIMIT 100
