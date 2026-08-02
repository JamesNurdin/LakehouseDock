WITH high_qty_items AS (
    SELECT inv.inv_item_sk
    FROM inventory inv
    JOIN date_dim d ON inv.inv_date_sk = d.d_date_sk
    WHERE inv.inv_quantity_on_hand >= 500
      AND d.d_year = 2001
)
SELECT
    sm.sm_type AS ship_mode_type,
    web.web_name AS website_name,
    SUM(ws.ws_net_profit) AS total_net_profit,
    SUM(ws.ws_ext_sales_price) AS total_sales_price,
    regexp_extract(sm.sm_carrier, '([A-Za-z]+)', 1) AS carrier_first_word,
    CONCAT(sm.sm_ship_mode_id, '-', sm.sm_code) AS ship_mode_code_concat,
    SUBSTRING(web.web_name, 1, 5) AS website_name_prefix
FROM web_sales ws
JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN web_site web ON ws.ws_web_site_sk = web.web_site_sk
JOIN date_dim d_sold ON ws.ws_sold_date_sk = d_sold.d_date_sk
WHERE ws.ws_item_sk IN (SELECT inv_item_sk FROM high_qty_items)
  AND regexp_like(sm.sm_carrier, '^Fed.*')
  AND web.web_name LIKE '%Online%'
  AND d_sold.d_year = 2001
GROUP BY
    sm.sm_type,
    web.web_name,
    regexp_extract(sm.sm_carrier, '([A-Za-z]+)', 1),
    CONCAT(sm.sm_ship_mode_id, '-', sm.sm_code),
    SUBSTRING(web.web_name, 1, 5)
HAVING SUM(ws.ws_ext_sales_price) > 5000

UNION

SELECT
    sm.sm_type AS ship_mode_type,
    web.web_name AS website_name,
    SUM(ws.ws_net_profit) AS total_net_profit,
    SUM(ws.ws_ext_sales_price) AS total_sales_price,
    regexp_extract(sm.sm_carrier, '([A-Za-z]+)', 1) AS carrier_first_word,
    CONCAT(sm.sm_ship_mode_id, '-', sm.sm_code) AS ship_mode_code_concat,
    SUBSTRING(web.web_name, 1, 5) AS website_name_prefix
FROM web_sales ws
JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN web_site web ON ws.ws_web_site_sk = web.web_site_sk
JOIN date_dim d_sold ON ws.ws_sold_date_sk = d_sold.d_date_sk
WHERE EXISTS (
    SELECT 1
    FROM inventory inv
    JOIN date_dim d_inv ON inv.inv_date_sk = d_inv.d_date_sk
    WHERE inv.inv_item_sk = ws.ws_item_sk
      AND inv.inv_quantity_on_hand < 100
      AND d_inv.d_year = 2001
)
  AND regexp_like(sm.sm_carrier, '^UPS.*')
  AND web.web_name LIKE '%Shop%'
  AND d_sold.d_year = 2001
GROUP BY
    sm.sm_type,
    web.web_name,
    regexp_extract(sm.sm_carrier, '([A-Za-z]+)', 1),
    CONCAT(sm.sm_ship_mode_id, '-', sm.sm_code),
    SUBSTRING(web.web_name, 1, 5)
HAVING SUM(ws.ws_ext_sales_price) > 1000
ORDER BY total_sales_price DESC
LIMIT 100
