SELECT
    d.d_fy_year,
    d.d_day_name,
    s.s_geography_class,
    s.s_county,
    w.w_state,
    SUM(fs.ws_ext_sales_price) AS total_sales,
    AVG(fs.ws_ext_discount_amt) AS avg_discount,
    COUNT(DISTINCT fs.ws_order_number) AS order_count,
    MAX(fs.ws_net_profit) AS max_profit,
    MIN(fs.ws_net_profit) AS min_profit,
    CASE
        WHEN SUM(fs.ws_net_profit) > 50000 THEN 'High'
        ELSE 'Low'
    END AS profit_category
FROM (
    SELECT
        ws.ws_sold_date_sk,
        ws.ws_warehouse_sk,
        ws.ws_ext_sales_price,
        ws.ws_ext_discount_amt,
        ws.ws_net_profit,
        ws.ws_order_number,
        ws.ws_ext_ship_cost,
        ws.ws_list_price
    FROM tpcds.web_sales ws
    WHERE ws.ws_ext_ship_cost > 1000
      AND ws.ws_list_price BETWEEN 50 AND 150
) fs
JOIN tpcds.date_dim d ON fs.ws_sold_date_sk = d.d_date_sk
JOIN tpcds.store s ON s.s_closed_date_sk = d.d_date_sk
JOIN tpcds.warehouse w ON fs.ws_warehouse_sk = w.w_warehouse_sk
WHERE d.d_fy_year = 1916
  AND d.d_day_name = 'Tuesday  '
  AND s.s_geography_class = 'Unknown'
  AND s.s_county = 'Fairfield County'
GROUP BY d.d_fy_year, d.d_day_name, s.s_geography_class, s.s_county, w.w_state
ORDER BY total_sales DESC
LIMIT 100
