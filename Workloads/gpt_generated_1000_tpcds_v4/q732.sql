WITH filtered_sales AS (
  SELECT
    ws.ws_order_number,
    ws.ws_sold_time_sk,
    ws.ws_item_sk,
    ws.ws_bill_addr_sk,
    ws.ws_net_paid,
    ws.ws_quantity,
    i.i_item_desc,
    i.i_product_name,
    t.t_sub_shift,
    ca.ca_city,
    ca.ca_state,
    wp.wp_url
  FROM web_sales ws
  JOIN item i ON ws.ws_item_sk = i.i_item_sk
  JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
  JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
  JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
  WHERE regexp_like(i.i_item_desc, '[A-Z]{3}[0-9]{2}')
    AND wp.wp_url LIKE 'http%://%/promo%'
)
SELECT
  CASE
    WHEN t_sub_shift = 'morning'    THEN 'Morning'
    WHEN t_sub_shift = 'afternoon' THEN 'Afternoon'
    ELSE 'Other'
  END AS shift_category,
  concat(ca_city, ', ', ca_state) AS location,
  regexp_extract(i_item_desc, '([A-Z]{3}[0-9]{2})', 1) AS item_code,
  sum(ws_net_paid)      AS total_net_paid,
  sum(ws_quantity)      AS total_quantity,
  count(DISTINCT ws_order_number) AS distinct_orders
FROM filtered_sales
GROUP BY
  CASE
    WHEN t_sub_shift = 'morning'    THEN 'Morning'
    WHEN t_sub_shift = 'afternoon' THEN 'Afternoon'
    ELSE 'Other'
  END,
  concat(ca_city, ', ', ca_state),
  regexp_extract(i_item_desc, '([A-Z]{3}[0-9]{2})', 1)
ORDER BY total_net_paid DESC
LIMIT 100
