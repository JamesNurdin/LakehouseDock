SELECT w.w_state, SUM(ws.ws_ext_sales_price) AS total_sales FROM web_sales ws JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk WHERE w.w_country = 'United States' GROUP BY w.w_state
