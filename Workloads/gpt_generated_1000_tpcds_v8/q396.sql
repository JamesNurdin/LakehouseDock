WITH intersect_items AS (
    SELECT ws_item_sk
    FROM web_sales
    WHERE ws_quantity > 10
    INTERSECT
    SELECT wr_item_sk
    FROM web_returns
    WHERE wr_return_quantity > 0
)
SELECT
    wsite.web_name,
    i.i_brand,
    SUM(ws.ws_net_paid) AS total_net_paid,
    AVG(ws.ws_sales_price) AS avg_sales_price,
    COUNT(DISTINCT ws.ws_order_number) AS distinct_orders,
    MIN(ws.ws_net_paid) AS min_net_paid,
    MAX(ws.ws_net_paid) AS max_net_paid
FROM web_sales ws
LEFT JOIN item i
    ON ws.ws_item_sk = i.i_item_sk
LEFT JOIN household_demographics hd_bill
    ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
LEFT JOIN customer_address ca_bill
    ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
LEFT JOIN household_demographics hd_ship
    ON ws.ws_ship_hdemo_sk = hd_ship.hd_demo_sk
LEFT JOIN customer_address ca_ship
    ON ws.ws_ship_addr_sk = ca_ship.ca_address_sk
LEFT JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
RIGHT OUTER JOIN web_site wsite
    ON ws.ws_web_site_sk = wsite.web_site_sk
LEFT JOIN web_returns wr
    ON ws.ws_item_sk = wr.wr_item_sk
   AND ws.ws_order_number = wr.wr_order_number
INNER JOIN intersect_items ii
    ON ws.ws_item_sk = ii.ws_item_sk
LEFT JOIN income_band ib
    ON hd_bill.hd_income_band_sk = ib.ib_income_band_sk
WHERE
    ca_bill.ca_state = 'CA'
    AND ca_bill.ca_location_type = 'single family'
    AND i.i_current_price BETWEEN 50 AND 200
    AND i.i_formulation LIKE '%steel%'
    AND i.i_rec_end_date >= DATE '2000-01-01'
    AND ws.ws_quantity > 5
GROUP BY GROUPING SETS (
    (wsite.web_name, i.i_brand),
    (wsite.web_name),
    (i.i_brand),
    ()
)
ORDER BY total_net_paid DESC
LIMIT 100
