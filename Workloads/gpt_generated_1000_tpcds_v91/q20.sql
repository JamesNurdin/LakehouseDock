WITH intersect_items AS (
    SELECT ws.ws_item_sk
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE d.d_quarter_name = '1905Q3'
      AND regexp_like(i.i_item_desc, '(?i)accounts')
    INTERSECT
    SELECT ws.ws_item_sk
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE i.i_category = 'Books'
      AND ib.ib_upper_bound >= 80000
)
SELECT
    i.i_category,
    i.i_brand,
    d.d_quarter_name,
    SUM(ws.ws_net_profit) AS total_net_profit,
    COUNT(DISTINCT ws.ws_order_number) AS num_orders,
    CASE WHEN SUM(ws.ws_net_profit) > 10000 THEN 'High' ELSE 'Low' END AS profit_level,
    CONCAT(ca.ca_city, ', ', ca.ca_state) AS customer_location,
    SUBSTRING(ca.ca_zip, 1, 5) AS zip_prefix,
    MAX(regexp_extract(i.i_item_desc, '(?i)accounts', 1)) AS matched_word
FROM web_sales ws
JOIN intersect_items ii ON ws.ws_item_sk = ii.ws_item_sk
JOIN item i ON ws.ws_item_sk = i.i_item_sk
JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
WHERE i.i_item_desc LIKE '%the%'
  AND ca.ca_city LIKE 'New%'
  AND d.d_holiday = 'N'
GROUP BY
    i.i_category,
    i.i_brand,
    d.d_quarter_name,
    ca.ca_city,
    ca.ca_state,
    ca.ca_zip
ORDER BY total_net_profit DESC
LIMIT 100
