WITH ws AS (
    SELECT
        ws.ws_order_number,
        ws.ws_sold_date_sk,
        ws.ws_sold_time_sk,
        ws.ws_item_sk,
        ws.ws_bill_customer_sk,
        ws.ws_ship_mode_sk,
        ws.ws_web_page_sk,
        ws.ws_web_site_sk,
        ws.ws_promo_sk,
        ws.ws_quantity,
        ws.ws_net_profit,
        ws.ws_ext_sales_price
    FROM tpcds.web_sales ws
    WHERE ws.ws_sold_date_sk BETWEEN 2450000 AND 2452000
)
SELECT
    web_site.web_name,
    ship_mode.sm_code,
    time_dim.t_meal_time,
    item.i_category,
    promotion.p_promo_name,
    COUNT(DISTINCT ws.ws_order_number) AS order_cnt,
    SUM(ws.ws_net_profit) AS total_profit,
    AVG(ws.ws_quantity) AS avg_quantity,
    MIN(ws.ws_sold_date_sk) AS first_sold_date_sk,
    SUM(catalog_returns.cr_return_amount) AS total_return_amount,
    SUM(web_returns.wr_return_amt) AS total_web_return_amt
FROM ws
JOIN tpcds.time_dim time_dim
    ON ws.ws_sold_time_sk = time_dim.t_time_sk
JOIN tpcds.item item
    ON ws.ws_item_sk = item.i_item_sk
JOIN tpcds.customer customer
    ON ws.ws_bill_customer_sk = customer.c_customer_sk
JOIN tpcds.ship_mode ship_mode
    ON ws.ws_ship_mode_sk = ship_mode.sm_ship_mode_sk
JOIN tpcds.promotion promotion
    ON ws.ws_promo_sk = promotion.p_promo_sk
JOIN tpcds.web_page web_page
    ON ws.ws_web_page_sk = web_page.wp_web_page_sk
JOIN tpcds.web_site web_site
    ON ws.ws_web_site_sk = web_site.web_site_sk
LEFT JOIN tpcds.catalog_returns catalog_returns
    ON catalog_returns.cr_item_sk = ws.ws_item_sk
LEFT JOIN tpcds.catalog_page catalog_page
    ON catalog_returns.cr_catalog_page_sk = catalog_page.cp_catalog_page_sk
LEFT JOIN tpcds.web_returns web_returns
    ON web_returns.wr_order_number = ws.ws_order_number
WHERE
    time_dim.t_meal_time = 'lunch'
    AND ship_mode.sm_code = 'AIR'
    AND web_site.web_country = 'United States'
    AND customer.c_birth_day = 23
GROUP BY
    web_site.web_name,
    ship_mode.sm_code,
    time_dim.t_meal_time,
    item.i_category,
    promotion.p_promo_name
HAVING
    SUM(ws.ws_net_profit) > 10000
    AND COUNT(DISTINCT ws.ws_order_number) > 10
ORDER BY total_profit DESC
LIMIT 100
