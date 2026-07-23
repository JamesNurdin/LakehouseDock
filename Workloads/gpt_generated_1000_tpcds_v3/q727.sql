SELECT DISTINCT w.w_warehouse_name, w.w_city, ws.ws_ext_tax
FROM warehouse w
JOIN web_sales ws ON ws.ws_warehouse_sk = w.w_warehouse_sk
WHERE w.w_warehouse_sq_ft > 600000
  AND ws.ws_ext_tax > 100
LIMIT 100
