WITH
    full_inv_wh AS (
        SELECT
            inv.inv_date_sk,
            inv.inv_item_sk,
            inv.inv_quantity_on_hand,
            wh.w_warehouse_sk,
            wh.w_warehouse_name,
            wh.w_city,
            wh.w_state
        FROM inventory inv
        FULL OUTER JOIN warehouse wh
            ON inv.inv_warehouse_sk = wh.w_warehouse_sk
    ),
    intersect_customers AS (
        SELECT c.c_customer_sk FROM customer c WHERE c.c_birth_country = 'United States'
        INTERSECT
        SELECT cr.cr_returning_customer_sk FROM catalog_returns cr WHERE cr.cr_return_amount > 0
    ),
    customer_returns AS (
        SELECT
            cr.cr_returning_customer_sk,
            SUM(cr.cr_return_amount) AS total_return_amount,
            COUNT(*) AS return_cnt,
            MAX(cr.cr_returned_date_sk) AS max_return_date_sk
        FROM catalog_returns cr
        JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
        WHERE d.d_year = 2000
        GROUP BY cr.cr_returning_customer_sk
    ),
    eligible_customers AS (
        SELECT
            c.c_customer_sk,
            c.c_first_name,
            c.c_last_name,
            c.c_email_address,
            cr.total_return_amount,
            cr.max_return_date_sk
        FROM customer c
        JOIN customer_returns cr ON c.c_customer_sk = cr.cr_returning_customer_sk
        WHERE NOT EXISTS (
                SELECT 1 FROM web_page wp
                WHERE wp.wp_customer_sk = c.c_customer_sk
                  AND wp.wp_url LIKE '%promo%'
            )
          AND c.c_customer_sk IN (SELECT c_customer_sk FROM intersect_customers)
    ),
    scalar_avg_return AS (
        SELECT AVG(cr_return_amount) AS avg_return_amount
        FROM catalog_returns
        WHERE cr_returned_date_sk = (
                SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2000
            )
    )
SELECT
    entity_id,
    entity_type,
    metric1,
    metric2,
    recent_return_cnt,
    source_flag
FROM (
    -- Customers branch
    SELECT
        ec.c_customer_sk AS entity_id,
        'customer' AS entity_type,
        ec.total_return_amount AS metric1,
        (SELECT avg_return_amount FROM scalar_avg_return) AS metric2,
        (SELECT COUNT(*) FROM catalog_returns cr2
             WHERE cr2.cr_returning_customer_sk = ec.c_customer_sk
               AND cr2.cr_returned_date_sk > ec.max_return_date_sk) AS recent_return_cnt,
        'eligible' AS source_flag
    FROM eligible_customers ec

    UNION

    -- Warehouses branch (full outer join result)
    SELECT
        COALESCE(fi.w_warehouse_sk, -1) AS entity_id,
        'warehouse' AS entity_type,
        SUM(fi.inv_quantity_on_hand) AS metric1,
        NULL AS metric2,
        NULL AS recent_return_cnt,
        'inventory' AS source_flag
    FROM full_inv_wh fi
    WHERE fi.inv_quantity_on_hand > 0 OR fi.w_warehouse_sk IS NOT NULL
    GROUP BY COALESCE(fi.w_warehouse_sk, -1)
) AS combined
ORDER BY metric1 DESC
LIMIT 100
