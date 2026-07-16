SELECT
    s.s_store_id,
    d_closed.d_year AS store_closed_year,
    d_sold.d_year AS sale_year,
    CASE
        WHEN d_sold.d_month_seq BETWEEN 1 AND 6 THEN 'H1'
        ELSE 'H2'
    END AS half_year,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    SUM(ss.ss_net_profit) AS total_profit,
    COUNT(DISTINCT ss.ss_item_sk) AS distinct_items_sold,
    COALESCE(SUM(cr.cr_net_loss), 0) AS total_return_loss,
    COUNT(DISTINCT cr.cr_item_sk) AS distinct_items_returned,
    COUNT(DISTINCT wp.wp_web_page_id) AS distinct_web_pages,
    SUM(wp.wp_image_count) AS total_images,
    SUM(CASE WHEN wp.wp_type = 'home' THEN 1 ELSE 0 END) AS home_page_count
FROM store_sales ss
INNER JOIN date_dim d_sold
    ON ss.ss_sold_date_sk = d_sold.d_date_sk
INNER JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
LEFT JOIN catalog_returns cr
    ON cr.cr_returned_date_sk = d_sold.d_date_sk
    AND cr.cr_item_sk = ss.ss_item_sk
LEFT JOIN date_dim d_closed
    ON s.s_closed_date_sk = d_closed.d_date_sk
LEFT JOIN web_page wp
    ON wp.wp_creation_date_sk = d_sold.d_date_sk
    OR wp.wp_access_date_sk = d_sold.d_date_sk
GROUP BY
    s.s_store_id,
    d_closed.d_year,
    d_sold.d_year,
    CASE
        WHEN d_sold.d_month_seq BETWEEN 1 AND 6 THEN 'H1'
        ELSE 'H2'
    END
HAVING
    SUM(ss.ss_ext_sales_price) > 1000
    AND COUNT(DISTINCT ss.ss_item_sk) >= 5
