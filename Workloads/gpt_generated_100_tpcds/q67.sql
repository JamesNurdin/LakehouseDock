SELECT
    wp.wp_type,
    d.d_year,
    d.d_month_seq AS month_seq,
    t.t_hour,
    hd.hd_buy_potential,
    ca.ca_state,
    i.i_category,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    SUM(ws.ws_net_profit) AS total_profit,
    COUNT(DISTINCT ws.ws_order_number) AS orders,
    AVG(ws.ws_quantity) AS avg_quantity,
    SUM(ws.ws_ext_sales_price) / COUNT(DISTINCT ws.ws_order_number) AS avg_sales_per_order
FROM web_sales ws
JOIN date_dim d
  ON ws.ws_sold_date_sk = d.d_date_sk
JOIN time_dim t
  ON ws.ws_sold_time_sk = t.t_time_sk
JOIN web_page wp
  ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN household_demographics hd
  ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
JOIN customer_address ca
  ON ws.ws_bill_addr_sk = ca.ca_address_sk
JOIN item i
  ON ws.ws_item_sk = i.i_item_sk
WHERE d.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
GROUP BY
    wp.wp_type,
    d.d_year,
    d.d_month_seq,
    t.t_hour,
    hd.hd_buy_potential,
    ca.ca_state,
    i.i_category
ORDER BY total_sales DESC
LIMIT 100
