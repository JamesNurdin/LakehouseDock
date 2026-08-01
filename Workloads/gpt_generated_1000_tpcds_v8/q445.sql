WITH
    store_agg AS (
        SELECT sr.sr_item_sk,
               sr.sr_addr_sk,
               SUM(sr.sr_return_quantity) AS store_qty,
               SUM(sr.sr_return_amt) AS store_amount
        FROM store_returns sr
        GROUP BY sr.sr_item_sk, sr.sr_addr_sk
    ),
    catalog_agg AS (
        SELECT cr.cr_item_sk,
               cr.cr_refunded_addr_sk,
               cr.cr_returning_addr_sk,
               cr.cr_warehouse_sk,
               SUM(cr.cr_return_quantity) AS catalog_qty,
               SUM(cr.cr_return_amount) AS catalog_amount
        FROM catalog_returns cr
        GROUP BY cr.cr_item_sk, cr.cr_refunded_addr_sk, cr.cr_returning_addr_sk, cr.cr_warehouse_sk
    ),
    full_item_promo AS (
        SELECT i.i_item_sk,
               i.i_product_name,
               p.p_promo_id,
               p.p_discount_active,
               p.p_cost
        FROM item i
        FULL OUTER JOIN promotion p ON p.p_item_sk = i.i_item_sk
    ),
    intersect_items AS (
        SELECT sr_item_sk AS item_sk FROM store_returns
        INTERSECT
        SELECT cr_item_sk FROM catalog_returns
    ),
    union_select AS (
        SELECT i.i_item_sk, i.i_brand, i.i_size, i.i_current_price
        FROM item i
        WHERE i.i_size = 'small'
        UNION
        SELECT i.i_item_sk, i.i_brand, i.i_size, i.i_current_price
        FROM item i
        WHERE i.i_color = 'red'
    )
SELECT
    i1.i_item_sk,
    i1.i_product_name,
    ca_store.ca_city AS store_city,
    ca_refund.ca_state AS refund_state,
    ca_return.ca_country AS return_country,
    w.w_warehouse_name,
    p1.p_promo_name,
    sa.store_qty,
    sa.store_amount,
    ca.catalog_qty,
    ca.catalog_amount,
    COUNT(DISTINCT fu.p_promo_id) AS distinct_promos,
    SUM(fu.p_cost) AS total_promo_cost
FROM
    store_agg sa
JOIN item i1
    ON sa.sr_item_sk = i1.i_item_sk                                   -- join 1
JOIN customer_address ca_store
    ON sa.sr_addr_sk = ca_store.ca_address_sk                         -- join 2
JOIN catalog_agg ca
    ON ca.cr_item_sk = i1.i_item_sk                                    -- join 3
JOIN customer_address ca_refund
    ON ca.cr_refunded_addr_sk = ca_refund.ca_address_sk               -- join 4
JOIN customer_address ca_return
    ON ca.cr_returning_addr_sk = ca_return.ca_address_sk               -- join 5
JOIN warehouse w
    ON ca.cr_warehouse_sk = w.w_warehouse_sk                           -- join 6
JOIN promotion p1
    ON p1.p_item_sk = i1.i_item_sk                                      -- join 7
JOIN full_item_promo fu
    ON fu.i_item_sk = i1.i_item_sk                                      -- join 8 (from full outer join CTE)
WHERE
    i1.i_item_sk IN (SELECT item_sk FROM intersect_items)               -- intersect usage
    AND EXISTS (
        SELECT 1
        FROM promotion p2
        WHERE p2.p_item_sk = i1.i_item_sk
          AND p2.p_discount_active = 'Y'
    )                                                                   -- correlated EXISTS
    AND i1.i_item_sk IN (SELECT i_item_sk FROM union_select)            -- UNION‑derived filter
GROUP BY
    i1.i_item_sk,
    i1.i_product_name,
    ca_store.ca_city,
    ca_refund.ca_state,
    ca_return.ca_country,
    w.w_warehouse_name,
    p1.p_promo_name,
    sa.store_qty,
    sa.store_amount,
    ca.catalog_qty,
    ca.catalog_amount
ORDER BY
    total_promo_cost DESC
LIMIT 100
