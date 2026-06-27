/*
   Net‑profit analysis per item, accounting for store‑sales revenue, store returns, catalog returns, and promotion costs.
   The query aggregates each fact table separately, then joins the results to the item dimension.
*/
SELECT
    i.i_item_id,
    i.i_product_name,
    i.i_brand,
    i.i_category,
    COALESCE(s.total_quantity, 0)               AS total_sales_quantity,
    COALESCE(s.total_net_profit, 0)             AS total_sales_net_profit,
    COALESCE(p.total_promo_cost, 0)             AS total_promo_cost,
    COALESCE(sr.total_return_qty, 0)            AS total_store_return_qty,
    COALESCE(sr.total_store_net_loss, 0)        AS total_store_net_loss,
    COALESCE(cr.total_return_qty, 0)            AS total_catalog_return_qty,
    COALESCE(cr.total_catalog_net_loss, 0)      AS total_catalog_net_loss,
    (COALESCE(s.total_net_profit, 0)
     - COALESCE(sr.total_store_net_loss, 0)
     - COALESCE(cr.total_catalog_net_loss, 0)
     - COALESCE(p.total_promo_cost, 0))          AS net_profit_after_returns_and_promos
FROM item i
LEFT JOIN (
    SELECT
        ss_item_sk,
        SUM(ss_quantity)   AS total_quantity,
        SUM(ss_net_profit) AS total_net_profit
    FROM store_sales
    GROUP BY ss_item_sk
) s
    ON i.i_item_sk = s.ss_item_sk
LEFT JOIN (
    SELECT
        p_item_sk,
        SUM(p_cost) AS total_promo_cost
    FROM promotion
    GROUP BY p_item_sk
) p
    ON i.i_item_sk = p.p_item_sk
LEFT JOIN (
    SELECT
        sr_item_sk,
        SUM(sr_return_quantity) AS total_return_qty,
        SUM(sr_net_loss)        AS total_store_net_loss
    FROM store_returns
    GROUP BY sr_item_sk
) sr
    ON i.i_item_sk = sr.sr_item_sk
LEFT JOIN (
    SELECT
        cr_item_sk,
        SUM(cr_return_quantity) AS total_return_qty,
        SUM(cr_net_loss)        AS total_catalog_net_loss
    FROM catalog_returns
    GROUP BY cr_item_sk
) cr
    ON i.i_item_sk = cr.cr_item_sk
ORDER BY net_profit_after_returns_and_promos DESC
LIMIT 100
