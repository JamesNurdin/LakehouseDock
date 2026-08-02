SELECT
    d.d_year AS year,
    cd.cd_gender AS gender,
    hd.hd_buy_potential AS buy_potential,
    s.s_state AS store_state,
    cp.cp_department AS catalog_department,
    SUM(ws.ws_net_paid_inc_ship) AS total_net_paid_inc_ship,
    AVG(ws.ws_ext_discount_amt) AS avg_discount_amt,
    COUNT(DISTINCT ws.ws_item_sk) AS distinct_items_sold,
    MIN(ws.ws_sales_price) AS min_sales_price,
    MAX(ws.ws_sales_price) AS max_sales_price,
    SUM(COALESCE(wr.wr_return_amt, 0)) AS total_return_amount,
    SUM(COALESCE(i.inv_quantity_on_hand, 0)) AS total_inventory_on_hand,
    COUNT(wr.wr_return_amt) AS return_count
FROM store_sales ss
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
JOIN store s ON ss.ss_store_sk = s.s_store_sk
FULL OUTER JOIN inventory i ON i.inv_date_sk = d.d_date_sk
JOIN catalog_page cp ON cp.cp_end_date_sk = d.d_date_sk
JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN web_site we ON ws.ws_web_site_sk = we.web_site_sk
LEFT JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
    AND wr.wr_item_sk = ws.ws_item_sk
    AND wr.wr_returned_date_sk = d.d_date_sk
WHERE d.d_year = 1999
  AND cd.cd_gender = 'M'
  AND hd.hd_buy_potential = '1001-5000'
  AND ws.ws_quantity > 10
GROUP BY d.d_year, cd.cd_gender, hd.hd_buy_potential, s.s_state, cp.cp_department
ORDER BY total_net_paid_inc_ship DESC
LIMIT 100
