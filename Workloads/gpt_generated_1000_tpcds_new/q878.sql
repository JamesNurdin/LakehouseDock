WITH inv_agg AS (
    SELECT
        inv_item_sk,
        inv_date_sk,
        SUM(inv_quantity_on_hand) AS total_qty
    FROM inventory
    GROUP BY inv_item_sk, inv_date_sk
)
SELECT
    d_sold.d_year AS sales_year,
    i.i_category,
    sm.sm_type AS ship_type,
    SUM(cs.cs_net_paid) AS total_net_paid,
    COUNT(DISTINCT cs.cs_order_number) AS orders,
    ws_best.ws_net_paid AS metric_value
FROM catalog_sales cs
JOIN date_dim d_sold ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship ON cs.cs_ship_date_sk = d_ship.d_date_sk
JOIN time_dim t_sold ON cs.cs_sold_time_sk = t_sold.t_time_sk
JOIN item i ON cs.cs_item_sk = i.i_item_sk
JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN customer_address ca_bill ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
JOIN customer_address ca_ship ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
JOIN inv_agg inv ON inv.inv_item_sk = cs.cs_item_sk AND inv.inv_date_sk = cs.cs_sold_date_sk
CROSS JOIN LATERAL (
    SELECT ws.ws_net_paid
    FROM web_sales ws
    WHERE ws.ws_item_sk = cs.cs_item_sk
    ORDER BY ws.ws_net_paid DESC
    LIMIT 1
) ws_best
WHERE d_sold.d_year = 2000
  AND cs.cs_net_paid > (SELECT MAX(cs3.cs_net_paid) FROM catalog_sales cs3)
GROUP BY d_sold.d_year, i.i_category, sm.sm_type, ws_best.ws_net_paid
HAVING SUM(cs.cs_net_paid) > 0

UNION DISTINCT

SELECT
    d_ws.d_year AS sales_year,
    i2.i_category,
    sm2.sm_type AS ship_type,
    SUM(ws.ws_net_paid) AS total_net_paid,
    COUNT(DISTINCT ws.ws_order_number) AS orders,
    MIN(sr.sr_net_loss) AS metric_value
FROM web_sales ws TABLESAMPLE BERNOULLI (10)
JOIN date_dim d_ws ON ws.ws_sold_date_sk = d_ws.d_date_sk
JOIN date_dim d_ws_ship ON ws.ws_ship_date_sk = d_ws_ship.d_date_sk
JOIN time_dim t_ws ON ws.ws_sold_time_sk = t_ws.t_time_sk
JOIN item i2 ON ws.ws_item_sk = i2.i_item_sk
JOIN ship_mode sm2 ON ws.ws_ship_mode_sk = sm2.sm_ship_mode_sk
JOIN customer_address ca_ws_bill ON ws.ws_bill_addr_sk = ca_ws_bill.ca_address_sk
JOIN customer_address ca_ws_ship ON ws.ws_ship_addr_sk = ca_ws_ship.ca_address_sk
JOIN web_site w_site ON ws.ws_web_site_sk = w_site.web_site_sk
FULL OUTER JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
JOIN inv_agg inv2 ON inv2.inv_item_sk = ws.ws_item_sk AND inv2.inv_date_sk = ws.ws_sold_date_sk
LEFT JOIN store_returns sr ON sr.sr_item_sk = ws.ws_item_sk AND sr.sr_returned_date_sk = d_ws.d_date_sk
WHERE d_ws.d_year = 2000
GROUP BY d_ws.d_year, i2.i_category, sm2.sm_type
HAVING SUM(ws.ws_net_paid) > 0

ORDER BY sales_year, total_net_paid DESC
LIMIT 100
