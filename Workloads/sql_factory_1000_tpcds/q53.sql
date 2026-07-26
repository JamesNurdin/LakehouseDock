SELECT w.web_site_id,
       ca_ship.ca_state AS ship_state,
       i.i_class AS item_class,
       AVG(ws.ws_ext_discount_amt) AS avg_discount,
       SUM(ws.ws_quantity) AS total_quantity_sold,
       DENSE_RANK() OVER (PARTITION BY w.web_site_id, ca_ship.ca_state ORDER BY AVG(ws.ws_ext_discount_amt) DESC) AS discount_class_rank,
       CASE WHEN AVG(ws.ws_ext_discount_amt) > 50 THEN 'Very High Discount'
            WHEN AVG(ws.ws_ext_discount_amt) > 20 THEN 'High Discount'
            WHEN AVG(ws.ws_ext_discount_amt) > 5 THEN 'Moderate Discount'
            ELSE 'Low Discount' END AS discount_category
FROM web_sales ws
JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
JOIN customer_address ca_ship ON ws.ws_ship_addr_sk = ca_ship.ca_address_sk
JOIN item i ON ws.ws_item_sk = i.i_item_sk
GROUP BY w.web_site_id, ca_ship.ca_state, i.i_class
HAVING SUM(ws.ws_quantity) > 0
ORDER BY w.web_site_id, ca_ship.ca_state, discount_class_rank
