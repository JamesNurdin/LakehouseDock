SELECT
  cp.cp_department,
  regexp_extract(i.i_item_desc, '([A-Z]{2}[0-9]{3})', 1) AS item_code,
  concat(i.i_brand, '-', i.i_color)                AS brand_color,
  sum(ws.ws_ext_sales_price)                      AS total_sales,
  count(DISTINCT ws.ws_order_number)              AS order_cnt
FROM web_sales ws
JOIN date_dim d_sale
  ON ws.ws_sold_date_sk = d_sale.d_date_sk
JOIN item i
  ON ws.ws_item_sk = i.i_item_sk
CROSS JOIN catalog_page cp
JOIN date_dim d_start
  ON cp.cp_start_date_sk = d_start.d_date_sk
JOIN date_dim d_end
  ON cp.cp_end_date_sk = d_end.d_date_sk
WHERE d_sale.d_date BETWEEN d_start.d_date AND d_end.d_date
  AND regexp_like(i.i_item_desc, '[A-Z]{2}[0-9]{3}')
  AND i.i_item_desc LIKE '%red%'
  AND cp.cp_description LIKE '%services%'
GROUP BY cp.cp_department,
         regexp_extract(i.i_item_desc, '([A-Z]{2}[0-9]{3})', 1),
         concat(i.i_brand, '-', i.i_color)
ORDER BY total_sales DESC
LIMIT 10
