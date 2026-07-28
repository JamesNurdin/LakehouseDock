WITH avg_price AS (
    SELECT ws.ws_item_sk,
           AVG(ws.ws_list_price) AS avg_list_price
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY ws.ws_item_sk
)
SELECT
    d.d_year,
    i.i_item_id,
    i.i_item_desc,
    w.w_warehouse_name,
    SUM(cs.cs_net_profit) AS total_net_profit,
    COUNT(*) AS sales_cnt,
    CASE
        WHEN SUM(cs.cs_net_profit) > COALESCE(ap.avg_list_price * 0.1, 0) THEN 'High Profit'
        ELSE 'Low Profit'
    END AS profit_category,
    regexp_extract(i.i_item_desc, '[0-9]{3}', 0) AS three_digit_code,
    CONCAT(w.w_city, ', ', w.w_state) AS warehouse_location
FROM catalog_sales cs
JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
JOIN item i ON cs.cs_item_sk = i.i_item_sk
JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
LEFT JOIN avg_price ap ON i.i_item_sk = ap.ws_item_sk
WHERE d.d_year BETWEEN 2000 AND 2002
  AND regexp_like(i.i_item_desc, '[A-Z]{2}[0-9]{3}')
  AND w.w_warehouse_name LIKE '%Warehouse%'
  AND EXISTS (
        SELECT 1
        FROM ship_mode sm
        WHERE sm.sm_ship_mode_sk = cs.cs_ship_mode_sk
          AND sm.sm_contract LIKE 'GNJ%'
    )
GROUP BY
    d.d_year,
    i.i_item_id,
    i.i_item_desc,
    w.w_warehouse_name,
    ap.avg_list_price,
    regexp_extract(i.i_item_desc, '[0-9]{3}', 0),
    CONCAT(w.w_city, ', ', w.w_state)
ORDER BY total_net_profit DESC
LIMIT 100
