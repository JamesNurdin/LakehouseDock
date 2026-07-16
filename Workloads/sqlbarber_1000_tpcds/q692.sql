SELECT
    ws.ws_order_number,
    ws.ws_quantity,
    ws.ws_sales_price,
    ws.ws_ext_sales_price,
    ws.ws_ext_tax,
    ws.ws_ext_discount_amt,
    ws.ws_ext_ship_cost,
    sm.sm_type,
    sm.sm_carrier,
    CASE 
        WHEN ws.ws_quantity > 10 THEN ws.ws_quantity * ws.ws_sales_price
        ELSE ws.ws_quantity * ws.ws_list_price
    END AS estimated_revenue,
    CASE sm.sm_type
        WHEN 'AIR' THEN 'Air Freight'
        WHEN 'RAIL' THEN 'Rail Freight'
        ELSE 'Other'
    END AS ship_mode_desc,
    (ws.ws_ext_sales_price - ws.ws_ext_tax) AS net_sales,
    (ws.ws_ext_sales_price - ws.ws_ext_tax - ws.ws_ext_discount_amt) AS net_sales_after_discount,
    (ws.ws_ext_ship_cost * 1.05) AS adjusted_ship_cost,
    CASE 
        WHEN ws.ws_ext_sales_price > 1000 THEN 'High'
        WHEN ws.ws_ext_sales_price > 500 THEN 'Medium'
        ELSE 'Low'
    END AS sales_category
FROM web_sales ws
JOIN ship_mode sm
    ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
WHERE ws.ws_sold_date_sk = 2452315
  AND sm.sm_carrier = 'GERMA               '
  AND ws.ws_quantity > 12
