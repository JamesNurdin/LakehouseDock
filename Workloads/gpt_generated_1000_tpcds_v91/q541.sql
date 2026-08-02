WITH
    catalog_data AS (
        SELECT
            cr.cr_returned_date_sk,
            cr.cr_item_sk,
            cr.cr_return_quantity,
            cr.cr_return_amount,
            cr.cr_net_loss,
            i.i_brand,
            i.i_category,
            i.i_product_name,
            w.w_warehouse_name,
            r.r_reason_desc,
            p.p_promo_name
        FROM catalog_returns cr
        JOIN item i ON cr.cr_item_sk = i.i_item_sk
        JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
        JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
        JOIN promotion p ON p.p_item_sk = i.i_item_sk
        WHERE i.i_brand_id IN (1, 2, 3)
          AND w.w_state = 'CA'
          AND cr.cr_return_amount > 0
          AND cr.cr_returned_time_sk > 20000
    ),
    web_data AS (
        SELECT
            wr.wr_returned_date_sk               AS cr_returned_date_sk,
            wr.wr_item_sk                         AS cr_item_sk,
            wr.wr_return_quantity                 AS cr_return_quantity,
            wr.wr_return_amt                     AS cr_return_amount,
            wr.wr_net_loss                       AS cr_net_loss,
            i.i_brand,
            i.i_category,
            i.i_product_name,
            NULL                                  AS w_warehouse_name,
            r.r_reason_desc,
            p.p_promo_name
        FROM web_returns wr
        JOIN item i ON wr.wr_item_sk = i.i_item_sk
        JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
        JOIN promotion p ON p.p_item_sk = i.i_item_sk
        WHERE i.i_brand_id IN (1, 2, 3)
          AND wr.wr_return_amt > 0
          AND wr.wr_returned_date_sk BETWEEN 24000 AND 25000
          AND wr.wr_return_quantity > 0
    ),
    combined AS (
        SELECT * FROM catalog_data
        UNION ALL
        SELECT * FROM web_data
    ),
    enriched AS (
        SELECT
            c.cr_returned_date_sk,
            c.cr_item_sk,
            c.cr_return_quantity,
            c.cr_return_amount,
            c.cr_net_loss,
            c.i_brand,
            c.i_category,
            c.i_product_name,
            c.w_warehouse_name,
            c.r_reason_desc,
            c.p_promo_name,
            l.total_quantity_for_item
        FROM combined c
        CROSS JOIN LATERAL (
            SELECT SUM(cr_return_quantity) AS total_quantity_for_item
            FROM combined c2
            WHERE c2.cr_item_sk = c.cr_item_sk
        ) AS l
    ),
    aggregated AS (
        SELECT
            i_brand,
            i_category,
            COUNT(DISTINCT i_product_name)            AS distinct_products,
            SUM(cr_return_amount)                     AS total_return_amount,
            SUM(DISTINCT cr_return_amount)            AS sum_distinct_return_amount,
            COUNT(DISTINCT r_reason_desc)             AS distinct_reasons,
            AVG(cr_net_loss)                          AS avg_net_loss,
            AVG(total_quantity_for_item)              AS avg_total_qty_for_item
        FROM enriched
        GROUP BY i_brand, i_category
        HAVING SUM(cr_return_amount) > 1000
    )
SELECT
    i_brand,
    i_category,
    distinct_products,
    total_return_amount,
    sum_distinct_return_amount,
    distinct_reasons,
    avg_net_loss,
    avg_total_qty_for_item
FROM aggregated
ORDER BY total_return_amount DESC
LIMIT 100
