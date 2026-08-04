WITH store_fact AS (
  SELECT
    d.d_date,
    s.s_store_name,
    i.i_product_name,
    ss.ss_quantity,
    ss.ss_net_paid,
    CASE WHEN sr.sr_return_quantity > 0 THEN 'Returned' ELSE 'Sold' END AS sales_status,
    ROW_NUMBER() OVER (PARTITION BY s.s_store_sk ORDER BY ss.ss_net_paid DESC) AS rank_num
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
  JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
  JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
  JOIN store s ON ss.ss_store_sk = s.s_store_sk
  LEFT JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
  LEFT JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
  LEFT JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk AND inv.inv_date_sk = d.d_date_sk
  WHERE d.d_year = 2001
    AND s.s_state = 'CA'
    AND p.p_discount_active = 'Y'
    AND cd.cd_gender = 'M'
    AND ca.ca_city = 'Los Angeles'
),
web_fact AS (
  SELECT
    d.d_date,
    we.web_name,
    i.i_product_name,
    ws.ws_quantity,
    ws.ws_net_paid,
    CASE WHEN wr.wr_return_quantity > 0 THEN 'Returned' ELSE 'Sold' END AS sales_status,
    DENSE_RANK() OVER (PARTITION BY we.web_site_sk ORDER BY ws.ws_net_paid DESC) AS rank_num
  FROM web_sales ws
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
  JOIN item i ON ws.ws_item_sk = i.i_item_sk
  JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
  JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
  JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
  JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
  JOIN web_site we ON ws.ws_web_site_sk = we.web_site_sk
  LEFT JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
  LEFT JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
  LEFT JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk AND inv.inv_date_sk = d.d_date_sk
  WHERE d.d_year = 2001
    AND we.web_state = 'CA'
    AND p.p_discount_active = 'Y'
    AND cd.cd_gender = 'F'
    AND wp.wp_url LIKE 'http://www.%'
)
SELECT
  d_date,
  s_store_name AS business_name,
  i_product_name,
  ss_quantity AS quantity,
  ss_net_paid AS net_paid,
  sales_status,
  rank_num
FROM store_fact
UNION DISTINCT
SELECT
  d_date,
  web_name AS business_name,
  i_product_name,
  ws_quantity AS quantity,
  ws_net_paid AS net_paid,
  sales_status,
  rank_num
FROM web_fact
ORDER BY d_date DESC, sales_status, business_name
LIMIT 100
