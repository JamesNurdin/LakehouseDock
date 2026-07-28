WITH avg_price AS (
    SELECT AVG(i_current_price) AS avg_price
    FROM item
)
SELECT
    d.d_year AS year,
    s.s_state AS state,
    SUM(ss.ss_net_paid) AS total_revenue,
    'store' AS channel
FROM store_sales ss
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
JOIN item i ON ss.ss_item_sk = i.i_item_sk
JOIN store s ON ss.ss_store_sk = s.s_store_sk
WHERE i.i_current_price > (SELECT avg_price FROM avg_price)
  AND d.d_year BETWEEN 2000 AND 2002
GROUP BY d.d_year, s.s_state

UNION ALL

SELECT
    d.d_year AS year,
    ca.ca_state AS state,
    SUM(ws.ws_net_paid) AS total_revenue,
    'web' AS channel
FROM web_sales ws
JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
JOIN item i ON ws.ws_item_sk = i.i_item_sk
JOIN customer_address ca ON ws.ws_ship_addr_sk = ca.ca_address_sk
WHERE i.i_current_price > (SELECT avg_price FROM avg_price)
  AND d.d_year BETWEEN 2000 AND 2002
GROUP BY d.d_year, ca.ca_state

ORDER BY year DESC, total_revenue DESC
