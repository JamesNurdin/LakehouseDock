WITH cat_data AS (
    SELECT
        i1.i_item_id AS item_id,
        r1.r_reason_desc AS reason_desc,
        cp.cp_department AS source_category,
        SUM(cr.cr_return_amount) AS total_return_amount,
        CASE WHEN cr.cr_return_quantity > 1 THEN 'MULTI' ELSE 'SINGLE' END AS return_type
    FROM
        store_sales ss
        INNER JOIN item i1 ON ss.ss_item_sk = i1.i_item_sk
        INNER JOIN promotion p1 ON ss.ss_promo_sk = p1.p_promo_sk
        INNER JOIN item i2 ON p1.p_item_sk = i2.i_item_sk
        INNER JOIN catalog_returns cr ON cr.cr_item_sk = i2.i_item_sk
        INNER JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
        INNER JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
        INNER JOIN reason r1 ON cr.cr_reason_sk = r1.r_reason_sk
    WHERE
        cp.cp_type = 'Standard'
    GROUP BY
        i1.i_item_id,
        r1.r_reason_desc,
        cp.cp_department,
        CASE WHEN cr.cr_return_quantity > 1 THEN 'MULTI' ELSE 'SINGLE' END
),
web_data AS (
    SELECT
        i1.i_item_id AS item_id,
        r2.r_reason_desc AS reason_desc,
        wp.wp_type AS source_category,
        SUM(wr.wr_return_amt) AS total_return_amount,
        CASE WHEN wr.wr_return_quantity > 1 THEN 'MULTI' ELSE 'SINGLE' END AS return_type
    FROM
        store_sales ss
        INNER JOIN item i1 ON ss.ss_item_sk = i1.i_item_sk
        INNER JOIN promotion p1 ON ss.ss_promo_sk = p1.p_promo_sk
        INNER JOIN web_returns wr ON wr.wr_item_sk = i1.i_item_sk
        INNER JOIN reason r2 ON wr.wr_reason_sk = r2.r_reason_sk
        INNER JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE
        wp.wp_autogen_flag = 'N'
    GROUP BY
        i1.i_item_id,
        r2.r_reason_desc,
        wp.wp_type,
        CASE WHEN wr.wr_return_quantity > 1 THEN 'MULTI' ELSE 'SINGLE' END
)
SELECT * FROM cat_data
UNION ALL
SELECT * FROM web_data
ORDER BY total_return_amount DESC
LIMIT 100
