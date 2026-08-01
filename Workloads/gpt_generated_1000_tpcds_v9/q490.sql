WITH
    agg_store_sales AS (
        SELECT
            ss.ss_item_sk,
            ss.ss_sold_date_sk,
            SUM(ss.ss_ext_sales_price) AS total_sales,
            SUM(ss.ss_quantity) AS total_quantity
        FROM store_sales ss
        GROUP BY ss.ss_item_sk, ss.ss_sold_date_sk
    ),
    catalog_items_not_in_store AS (
        SELECT cr.cr_item_sk
        FROM catalog_returns cr
        EXCEPT
        SELECT ss.ss_item_sk
        FROM store_sales ss
    )
SELECT
    d_sales.d_date,
    d_sales.d_year,
    i.i_item_id,
    i.i_product_name,
    i.i_brand,
    agg_ss.total_sales,
    agg_ss.total_quantity,
    COALESCE(sr.sr_return_quantity, 0) AS store_return_qty,
    COALESCE(cr.cr_return_quantity, 0) AS catalog_return_qty,
    COALESCE(ws.ws_quantity, 0) AS web_quantity,
    cp.cp_catalog_number,
    wp.wp_url,
    r.r_reason_desc,
    RANK() OVER (PARTITION BY d_sales.d_year ORDER BY agg_ss.total_sales DESC) AS sales_rank_year,
    SUM(agg_ss.total_sales) OVER (PARTITION BY i.i_brand ORDER BY d_sales.d_date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS brand_7day_sales,
    lr.total_store_return_qty,
    CASE WHEN cis.cr_item_sk IS NOT NULL THEN 1 ELSE 0 END AS catalog_not_in_store_flag
FROM agg_store_sales agg_ss
JOIN date_dim d_sales
    ON d_sales.d_date_sk = agg_ss.ss_sold_date_sk
JOIN item i
    ON i.i_item_sk = agg_ss.ss_item_sk
FULL OUTER JOIN store_returns sr
    ON sr.sr_item_sk = agg_ss.ss_item_sk
LEFT JOIN date_dim d_return
    ON d_return.d_date_sk = sr.sr_returned_date_sk
LEFT JOIN time_dim t_return
    ON t_return.t_time_sk = sr.sr_return_time_sk
LEFT JOIN customer_address ca_sr
    ON ca_sr.ca_address_sk = sr.sr_addr_sk
LEFT JOIN reason r
    ON r.r_reason_sk = sr.sr_reason_sk
LEFT JOIN web_sales ws
    ON ws.ws_item_sk = i.i_item_sk
LEFT JOIN web_page wp
    ON wp.wp_web_page_sk = ws.ws_web_page_sk
LEFT JOIN catalog_returns cr
    ON cr.cr_item_sk = i.i_item_sk
LEFT JOIN catalog_page cp
    ON cp.cp_catalog_page_sk = cr.cr_catalog_page_sk
LEFT JOIN date_dim d_cr
    ON d_cr.d_date_sk = cr.cr_returned_date_sk
LEFT JOIN time_dim t_cr
    ON t_cr.t_time_sk = cr.cr_returned_time_sk
LEFT JOIN customer_address ca_cr_refunded
    ON ca_cr_refunded.ca_address_sk = cr.cr_refunded_addr_sk
LEFT JOIN customer_address ca_cr_returning
    ON ca_cr_returning.ca_address_sk = cr.cr_returning_addr_sk
LEFT JOIN date_dim d_cp_start
    ON d_cp_start.d_date_sk = cp.cp_start_date_sk
LEFT JOIN date_dim d_cp_end
    ON d_cp_end.d_date_sk = cp.cp_end_date_sk
LEFT JOIN date_dim d_wp_creation
    ON d_wp_creation.d_date_sk = wp.wp_creation_date_sk
LEFT JOIN date_dim d_wp_access
    ON d_wp_access.d_date_sk = wp.wp_access_date_sk
LEFT JOIN catalog_items_not_in_store cis
    ON cis.cr_item_sk = agg_ss.ss_item_sk
CROSS JOIN LATERAL (
    SELECT SUM(sr2.sr_return_quantity) AS total_store_return_qty
    FROM store_returns sr2
    WHERE sr2.sr_item_sk = i.i_item_sk
) lr
WHERE
    d_sales.d_year = 1908
    AND i.i_brand_id = 5
    AND r.r_reason_desc = 'Damaged'
    AND cp.cp_department = 'Books'
ORDER BY
    sales_rank_year,
    agg_ss.total_sales DESC
LIMIT 100
