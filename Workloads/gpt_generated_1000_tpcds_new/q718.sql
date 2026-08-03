WITH
    /* Sample a fraction of inventory */
    sample_inv AS (
        SELECT *
        FROM inventory TABLESAMPLE BERNOULLI (10)
    ),
    /* First filtered join path */
    joined1 AS (
        SELECT
            cp.cp_catalog_page_sk,
            cp.cp_catalog_number,
            cp.cp_type,
            d.d_date,
            cr.cr_return_amount,
            cr.cr_return_quantity,
            inv.inv_quantity_on_hand,
            w.w_warehouse_id,
            w.w_state,
            cr.cr_returned_date_sk,
            cr.cr_item_sk
        FROM catalog_page cp
        JOIN catalog_returns cr
          ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
        JOIN date_dim d
          ON cr.cr_returned_date_sk = d.d_date_sk
        JOIN sample_inv inv
          ON inv.inv_date_sk = d.d_date_sk
        JOIN warehouse w
          ON inv.inv_warehouse_sk = w.w_warehouse_sk
        WHERE cp.cp_type IN ('quarterly','monthly')
          AND cp.cp_catalog_number BETWEEN 5 AND 20
          AND d.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
          AND inv.inv_quantity_on_hand > 500
          AND w.w_state = 'CA'
          AND cr.cr_return_amount > 100
          AND cr.cr_return_quantity > 1
    ),
    /* Second filtered join path with different predicates */
    joined2 AS (
        SELECT
            cp.cp_catalog_page_sk,
            cp.cp_catalog_number,
            cp.cp_type,
            d.d_date,
            cr.cr_return_amount,
            cr.cr_return_quantity,
            inv.inv_quantity_on_hand,
            w.w_warehouse_id,
            w.w_state,
            cr.cr_returned_date_sk,
            cr.cr_item_sk
        FROM catalog_page cp
        JOIN catalog_returns cr
          ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
        JOIN date_dim d
          ON cr.cr_returned_date_sk = d.d_date_sk
        JOIN inventory inv
          ON inv.inv_date_sk = d.d_date_sk
        JOIN warehouse w
          ON inv.inv_warehouse_sk = w.w_warehouse_sk
        WHERE cp.cp_type = 'bi-annual'
          AND cp.cp_catalog_number >= 10
          AND d.d_date BETWEEN DATE '2002-01-01' AND DATE '2002-06-30'
          AND inv.inv_quantity_on_hand BETWEEN 600 AND 900
          AND w.w_gmt_offset > -5
          AND cr.cr_return_amount BETWEEN 50 AND 500
          AND cr.cr_return_quantity <= 5
    ),
    /* Union of the two filtered result sets (distinct) */
    unioned AS (
        SELECT
            cp_catalog_page_sk,
            cp_catalog_number,
            cp_type,
            d_date,
            cr_return_amount,
            cr_return_quantity,
            inv_quantity_on_hand,
            w_warehouse_id,
            w_state,
            cr_returned_date_sk,
            cr_item_sk
        FROM joined1
        UNION
        SELECT
            cp_catalog_page_sk,
            cp_catalog_number,
            cp_type,
            d_date,
            cr_return_amount,
            cr_return_quantity,
            inv_quantity_on_hand,
            w_warehouse_id,
            w_state,
            cr_returned_date_sk,
            cr_item_sk
        FROM joined2
    ),
    /* Intersection of catalog page keys that appear in both paths */
    intersect_keys AS (
        SELECT cp_catalog_page_sk FROM joined1
        INTERSECT
        SELECT cp_catalog_page_sk FROM joined2
    ),
    /* Apply anti‑join, window functions and derived column */
    final_filtered AS (
        SELECT
            u.cp_catalog_page_sk,
            u.cp_catalog_number,
            u.cp_type,
            u.d_date,
            u.cr_return_amount,
            u.cr_return_quantity,
            u.inv_quantity_on_hand,
            u.w_warehouse_id,
            u.w_state,
            CASE WHEN u.w_state = 'CA' THEN 'West Coast' ELSE 'Other' END AS region_desc,
            RANK() OVER (ORDER BY u.inv_quantity_on_hand DESC) AS qty_rank,
            ROW_NUMBER() OVER (PARTITION BY u.cp_catalog_page_sk ORDER BY u.cr_return_amount DESC) AS rn_amount
        FROM unioned u
        WHERE NOT EXISTS (
            SELECT 1
            FROM catalog_returns crx
            WHERE crx.cr_item_sk = u.cr_item_sk
              AND crx.cr_returned_date_sk = u.cr_returned_date_sk
              AND crx.cr_return_amount <> u.cr_return_amount
        )
          AND u.cp_catalog_page_sk IN (SELECT cp_catalog_page_sk FROM intersect_keys)
    )
SELECT
    cp_catalog_page_sk,
    cp_catalog_number,
    cp_type,
    d_date,
    cr_return_amount,
    cr_return_quantity,
    inv_quantity_on_hand,
    w_warehouse_id,
    w_state,
    region_desc,
    qty_rank,
    rn_amount
FROM final_filtered
ORDER BY qty_rank ASC, cr_return_amount DESC
OFFSET 10 ROWS FETCH NEXT 20 ROWS ONLY
