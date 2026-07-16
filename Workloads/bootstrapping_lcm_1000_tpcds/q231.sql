SELECT
    d_sales.d_year,
    d_sales.d_current_month,
    store.s_state,
    item.i_category,
    COUNT(*) AS transaction_count,
    SUM(ss_ext_sales_price) AS total_sales,
    SUM(ss_ext_discount_amt) AS total_discount,
    AVG(ss_net_profit) AS avg_profit,
    COUNT(DISTINCT web_page.wp_web_page_id) AS distinct_pages,
    SUM(web_page.wp_image_count) AS total_images,
    CASE WHEN SUM(ss_ext_sales_price) > 100000 THEN 'High' ELSE 'Low' END AS sales_volume_category
FROM store_sales
JOIN date_dim AS d_sales
    ON store_sales.ss_sold_date_sk = d_sales.d_date_sk
JOIN item
    ON store_sales.ss_item_sk = item.i_item_sk
JOIN store
    ON store_sales.ss_store_sk = store.s_store_sk
JOIN date_dim AS d_store_closed
    ON store.s_closed_date_sk = d_store_closed.d_date_sk
JOIN web_page
    ON web_page.wp_creation_date_sk = d_sales.d_date_sk
JOIN date_dim AS d_web_access
    ON web_page.wp_access_date_sk = d_web_access.d_date_sk
WHERE d_sales.d_year = 2022
GROUP BY
    d_sales.d_year,
    d_sales.d_current_month,
    store.s_state,
    item.i_category
HAVING COUNT(*) > 5
ORDER BY total_sales DESC
LIMIT 100
