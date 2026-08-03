WITH
    cr_agg AS (
        SELECT
            cr.cr_item_sk,
            i.i_item_id,
            i.i_product_name,
            i.i_category,
            i.i_brand,
            SUM(cr.cr_return_amount) AS total_cr_amount,
            COUNT(*) AS cnt_cr
        FROM catalog_returns cr
        JOIN item i ON cr.cr_item_sk = i.i_item_sk
        JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
        JOIN time_dim td ON cr.cr_returned_time_sk = td.t_time_sk
        JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
        JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
        WHERE cr.cr_returned_date_sk BETWEEN 2450000 AND 2459999
          AND cr.cr_return_amount > 0
          AND i.i_current_price > 10
          AND ca.ca_country = 'United States'
        GROUP BY
            cr.cr_item_sk,
            i.i_item_id,
            i.i_product_name,
            i.i_category,
            i.i_brand
    ),
    sr_agg AS (
        SELECT
            sr.sr_item_sk,
            i.i_item_id,
            i.i_product_name,
            i.i_category,
            i.i_brand,
            SUM(sr.sr_return_amt) AS total_sr_amount,
            COUNT(*) AS cnt_sr
        FROM store_returns sr
        TABLESAMPLE BERNOULLI (10)
        JOIN item i ON sr.sr_item_sk = i.i_item_sk
        JOIN store s ON sr.sr_store_sk = s.s_store_sk
        JOIN time_dim td ON sr.sr_return_time_sk = td.t_time_sk
        JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
        JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
        WHERE sr.sr_returned_date_sk BETWEEN 2450000 AND 2459999
          AND sr.sr_return_amt > 0
          AND s.s_state = 'CA'
          AND ca.ca_state = 'CA'
        GROUP BY
            sr.sr_item_sk,
            i.i_item_id,
            i.i_product_name,
            i.i_category,
            i.i_brand
    ),
    intersect_items AS (
        SELECT cr_item_sk FROM catalog_returns
        INTERSECT
        SELECT sr_item_sk FROM store_returns
    ),
    union_items AS (
        SELECT cr_item_sk AS item_sk, total_cr_amount, cnt_cr, CAST(NULL AS DOUBLE) AS total_sr_amount, CAST(NULL AS BIGINT) AS cnt_sr
        FROM cr_agg
        UNION DISTINCT
        SELECT sr_item_sk, CAST(NULL AS DOUBLE), CAST(NULL AS BIGINT), total_sr_amount, cnt_sr
        FROM sr_agg
    ),
    full_inv AS (
        SELECT
            COALESCE(inv.inv_item_sk, u.item_sk) AS item_sk,
            inv.inv_quantity_on_hand,
            u.total_cr_amount,
            u.total_sr_amount,
            u.cnt_cr,
            u.cnt_sr
        FROM inventory inv
        FULL OUTER JOIN union_items u ON inv.inv_item_sk = u.item_sk
    ),
    filtered_inv AS (
        SELECT *
        FROM full_inv
        WHERE inv_quantity_on_hand > 0
          AND item_sk IN (SELECT i_item_sk FROM item WHERE i_category = 'Electronics')
    )
SELECT
    i.i_item_id,
    i.i_product_name,
    i.i_category,
    i.i_brand,
    fi.inv_quantity_on_hand,
    fi.total_cr_amount,
    fi.total_sr_amount,
    ca.ca_state,
    sm.sm_type,
    wp.wp_link_count,
    (COALESCE(fi.total_cr_amount, 0) + COALESCE(fi.total_sr_amount, 0)) AS combined_amount
FROM filtered_inv fi
JOIN item i ON fi.item_sk = i.i_item_sk
LEFT JOIN catalog_returns cr ON cr.cr_item_sk = i.i_item_sk
LEFT JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
LEFT JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
LEFT JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
LEFT JOIN web_page wp ON wp.wp_customer_sk = c.c_customer_sk
WHERE
    (fi.total_cr_amount IS NOT NULL OR fi.total_sr_amount IS NOT NULL)
    AND ca.ca_state = 'CA'
    AND sm.sm_type = 'AIR'
    AND wp.wp_link_count > 5
ORDER BY combined_amount DESC
LIMIT 100
