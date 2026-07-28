WITH distinct_ship AS (
    SELECT DISTINCT sm_ship_mode_sk
    FROM ship_mode
    WHERE sm_type = 'AIR'
),
sales_data AS (
    SELECT
        ws.ws_order_number,
        ws.ws_sold_date_sk,
        ws.ws_sold_time_sk,
        ws.ws_quantity,
        ws.ws_ext_list_price,
        ws.ws_net_paid,
        ws.ws_bill_hdemo_sk,
        ws.ws_bill_addr_sk,
        ws.ws_ship_mode_sk,
        ws.ws_web_site_sk,
        ws.ws_web_page_sk
    FROM web_sales ws
    JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
    JOIN distinct_ship ds ON ws.ws_ship_mode_sk = ds.sm_ship_mode_sk
    JOIN web_site wsit ON ws.ws_web_site_sk = wsit.web_site_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    WHERE td.t_time IN (9, 16, 11)
      AND td.t_meal_time = 'breakfast'
      AND wsit.web_rec_start_date BETWEEN DATE '2000-01-01' AND DATE '2002-12-31'
      AND ws.ws_quantity > 2
      AND ws.ws_ext_list_price > 1000
)
SELECT
    wsit.web_name,
    sm.sm_type,
    SUM(sales_data.ws_net_paid) AS total_net_paid,
    AVG(sales_data.ws_ext_list_price) AS avg_ext_list_price,
    COUNT(DISTINCT sales_data.ws_order_number) AS distinct_orders,
    MIN(sales_data.ws_sold_date_sk) AS min_sold_date_sk,
    MAX(sales_data.ws_sold_date_sk) AS max_sold_date_sk
FROM sales_data
JOIN web_site wsit ON sales_data.ws_web_site_sk = wsit.web_site_sk
JOIN ship_mode sm ON sales_data.ws_ship_mode_sk = sm.sm_ship_mode_sk
WHERE EXISTS (
    SELECT 1
    FROM catalog_returns cr
    WHERE cr.cr_returned_time_sk = sales_data.ws_sold_time_sk
      AND cr.cr_ship_mode_sk = sales_data.ws_ship_mode_sk
      AND cr.cr_refunded_addr_sk = sales_data.ws_bill_addr_sk
      AND cr.cr_refunded_hdemo_sk = sales_data.ws_bill_hdemo_sk
      AND cr.cr_return_amount > 100
)
GROUP BY ROLLUP (wsit.web_name, sm.sm_type)
HAVING SUM(sales_data.ws_net_paid) > 10000
   AND COUNT(DISTINCT sales_data.ws_order_number) >= 5
ORDER BY wsit.web_name, sm.sm_type
