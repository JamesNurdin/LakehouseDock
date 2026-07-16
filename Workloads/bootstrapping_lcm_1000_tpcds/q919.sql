SELECT
    sold_date.d_current_year AS sales_year,
    sold_date.d_quarter_name AS sales_quarter,
    sold_date.d_day_name AS sold_day_name,
    ship_date.d_day_name AS ship_day_name,
    store.s_store_name,
    store.s_state,
    COUNT(DISTINCT web_sales.ws_order_number) AS order_count,
    SUM(web_sales.ws_sales_price * web_sales.ws_quantity) AS total_sales,
    SUM(web_sales.ws_ext_discount_amt) AS total_discount,
    AVG(web_sales.ws_net_profit) AS avg_profit,
    MAX(web_sales.ws_ext_sales_price) AS max_sales_price,
    MIN(web_sales.ws_net_paid_inc_tax) AS min_net_paid_inc_tax,
    COUNT(DISTINCT web_page.wp_web_page_id) AS distinct_pages,
    MAX(web_page.wp_image_count) AS max_image_count,
    MIN(web_page.wp_char_count) AS min_char_count,
    creation_date.d_date AS page_creation_date,
    access_date.d_date AS page_access_date,
    ship_date.d_date AS ship_date,
    sold_date.d_date AS sold_date
FROM web_sales
JOIN date_dim AS sold_date
    ON web_sales.ws_sold_date_sk = sold_date.d_date_sk
JOIN date_dim AS ship_date
    ON web_sales.ws_ship_date_sk = ship_date.d_date_sk
JOIN web_page
    ON web_sales.ws_web_page_sk = web_page.wp_web_page_sk
JOIN date_dim AS creation_date
    ON web_page.wp_creation_date_sk = creation_date.d_date_sk
JOIN date_dim AS access_date
    ON web_page.wp_access_date_sk = access_date.d_date_sk
JOIN store
    ON store.s_closed_date_sk = sold_date.d_date_sk
WHERE sold_date.d_year = 2022
  AND store.s_state = 'CA'
GROUP BY
    sold_date.d_current_year,
    sold_date.d_quarter_name,
    sold_date.d_day_name,
    ship_date.d_day_name,
    store.s_store_name,
    store.s_state,
    creation_date.d_date,
    access_date.d_date,
    ship_date.d_date,
    sold_date.d_date
HAVING COUNT(DISTINCT web_sales.ws_order_number) > 10
ORDER BY total_sales DESC
LIMIT 100
