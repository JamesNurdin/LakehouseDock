WITH ws_base AS (
    SELECT
        ws.ws_sold_date_sk,
        ws.ws_sold_time_sk,
        ws.ws_item_sk,
        ws.ws_bill_customer_sk,
        ws.ws_bill_hdemo_sk,
        ws.ws_ship_customer_sk,
        ws.ws_ship_hdemo_sk,
        ws.ws_web_page_sk,
        ws.ws_web_site_sk,
        ws.ws_warehouse_sk,
        ws.ws_order_number,
        ws.ws_net_paid,
        ws.ws_ext_ship_cost,
        wh.w_warehouse_name AS warehouse_name,
        wsite.web_name AS site_name
    FROM web_sales ws
    LEFT JOIN warehouse wh
        ON ws.ws_warehouse_sk = wh.w_warehouse_sk
    LEFT JOIN web_site wsite
        ON ws.ws_web_site_sk = wsite.web_site_sk
    LEFT JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
)
SELECT
    i.i_category,
    td.t_hour,
    ws_base.warehouse_name,
    ws_base.site_name,
    COUNT(DISTINCT c_bill.c_customer_id) AS distinct_bill_customers,
    COUNT(DISTINCT c_ship.c_customer_id) AS distinct_ship_customers,
    SUM(ws_base.ws_net_paid) AS total_net_paid,
    SUM(cs.cs_net_paid) AS total_catalog_net_paid,
    SUM(ws_base.ws_ext_ship_cost) AS total_ship_cost,
    SUM(COALESCE(wr.wr_return_quantity, 0)) AS total_return_quantity,
    COUNT(DISTINCT wp2.wp_url) AS distinct_return_pages
FROM ws_base
JOIN time_dim td
    ON ws_base.ws_sold_time_sk = td.t_time_sk
JOIN item i
    ON ws_base.ws_item_sk = i.i_item_sk
JOIN customer c_bill
    ON ws_base.ws_bill_customer_sk = c_bill.c_customer_sk
JOIN household_demographics hd_bill
    ON ws_base.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
JOIN customer c_ship
    ON ws_base.ws_ship_customer_sk = c_ship.c_customer_sk
JOIN household_demographics hd_ship
    ON ws_base.ws_ship_hdemo_sk = hd_ship.hd_demo_sk
JOIN store_sales ss
    ON ss.ss_item_sk = i.i_item_sk
   AND ss.ss_sold_time_sk = td.t_time_sk
JOIN catalog_sales cs
    ON cs.cs_item_sk = i.i_item_sk
   AND cs.cs_sold_time_sk = td.t_time_sk
LEFT JOIN web_returns wr
    ON wr.wr_order_number = ws_base.ws_order_number
   AND wr.wr_item_sk = i.i_item_sk
LEFT JOIN web_page wp2
    ON wr.wr_web_page_sk = wp2.wp_web_page_sk
GROUP BY
    i.i_category,
    td.t_hour,
    ws_base.warehouse_name,
    ws_base.site_name
HAVING SUM(ws_base.ws_net_paid) > 10000
ORDER BY total_net_paid DESC
LIMIT 100
