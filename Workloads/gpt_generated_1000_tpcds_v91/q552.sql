WITH common_items AS (
    SELECT ss.ss_item_sk AS item_sk
    FROM store_sales ss
    JOIN date_dim d1 ON ss.ss_sold_date_sk = d1.d_date_sk
    WHERE d1.d_year = 2000
    INTERSECT
    SELECT ws.ws_item_sk AS item_sk
    FROM web_sales ws
    JOIN date_dim d2 ON ws.ws_sold_date_sk = d2.d_date_sk
    WHERE d2.d_year = 2000
)
SELECT
    d_sold.d_year AS sales_year,
    i.i_category AS item_category,
    s.s_store_name AS store_name,
    COUNT(DISTINCT c.c_customer_id) AS distinct_customers,
    SUM(ss.ss_ext_sales_price) AS total_store_sales,
    SUM(ws.ws_ext_sales_price) AS total_web_sales,
    CASE WHEN SUM(ss.ss_ext_sales_price) > SUM(ws.ws_ext_sales_price) THEN 'Store Higher' ELSE 'Web Higher or Equal' END AS sales_channel_comparison,
    SUM(CASE WHEN hd.hd_buy_potential = '>10000' THEN ss.ss_ext_sales_price ELSE 0 END) AS high_potential_sales,
    SUM(cr.cr_net_loss) AS total_catalog_return_loss,
    SUM(sr.sr_net_loss) AS total_store_return_loss,
    SUM(ws.ws_ext_ship_cost) AS total_web_ship_cost,
    COUNT(*) FILTER (WHERE sm_ws.sm_type = 'AIR') AS air_shipments_web,
    COUNT(*) FILTER (WHERE sm_cr.sm_type = 'AIR') AS air_shipments_catalog
FROM common_items ci
JOIN store_sales ss ON ss.ss_item_sk = ci.item_sk
JOIN web_sales ws ON ws.ws_item_sk = ci.item_sk
-- date dimensions for store and web sales
JOIN date_dim d_sold ON ss.ss_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ws_sold ON ws.ws_sold_date_sk = d_ws_sold.d_date_sk
-- item dimension
JOIN item i ON i.i_item_sk = ss.ss_item_sk
-- customer and related dimensions (store side)
JOIN customer c ON c.c_customer_sk = ss.ss_customer_sk
JOIN household_demographics hd ON hd.hd_demo_sk = ss.ss_hdemo_sk
JOIN customer_address ca ON ca.ca_address_sk = ss.ss_addr_sk
-- store dimension
JOIN store s ON s.s_store_sk = ss.ss_store_sk
-- store returns and related dimensions
LEFT JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number AND sr.sr_item_sk = ss.ss_item_sk
LEFT JOIN reason r_sr ON r_sr.r_reason_sk = sr.sr_reason_sk
LEFT JOIN date_dim d_sr_return ON d_sr_return.d_date_sk = sr.sr_returned_date_sk
-- catalog returns and related dimensions
LEFT JOIN catalog_returns cr ON cr.cr_item_sk = i.i_item_sk
LEFT JOIN reason r_cr ON r_cr.r_reason_sk = cr.cr_reason_sk
LEFT JOIN catalog_page cp ON cp.cp_catalog_page_sk = cr.cr_catalog_page_sk
LEFT JOIN ship_mode sm_cr ON sm_cr.sm_ship_mode_sk = cr.cr_ship_mode_sk
LEFT JOIN date_dim d_cr_return ON d_cr_return.d_date_sk = cr.cr_returned_date_sk
-- web sales related dimensions
LEFT JOIN web_page wp ON wp.wp_web_page_sk = ws.ws_web_page_sk
LEFT JOIN web_site wsite ON wsite.web_site_sk = ws.ws_web_site_sk
LEFT JOIN ship_mode sm_ws ON sm_ws.sm_ship_mode_sk = ws.ws_ship_mode_sk
LEFT JOIN date_dim d_wp_creation ON d_wp_creation.d_date_sk = wp.wp_creation_date_sk
LEFT JOIN date_dim d_wp_access ON d_wp_access.d_date_sk = wp.wp_access_date_sk
LEFT JOIN date_dim d_wsite_open ON d_wsite_open.d_date_sk = wsite.web_open_date_sk
LEFT JOIN date_dim d_wsite_close ON d_wsite_close.d_date_sk = wsite.web_close_date_sk
GROUP BY
    d_sold.d_year,
    i.i_category,
    s.s_store_name
ORDER BY total_store_sales DESC
LIMIT 100
