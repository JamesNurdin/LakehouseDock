(SELECT
    'store' AS sales_channel,
    ss.ss_sold_date_sk AS sale_date_sk,
    ca.ca_state,
    i.i_item_id,
    ss.ss_quantity,
    ss.ss_net_profit
FROM tpcds.store_sales ss
JOIN tpcds.time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
JOIN tpcds.item i ON ss.ss_item_sk = i.i_item_sk
JOIN tpcds.customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
WHERE td.t_hour BETWEEN 9 AND 17
  AND td.t_am_pm = 'PM'
  AND ca.ca_state IN ('CA','NY','TX'))
UNION ALL
(SELECT
    'web' AS sales_channel,
    ws.ws_sold_date_sk AS sale_date_sk,
    ca.ca_state,
    i.i_item_id,
    ws.ws_quantity,
    ws.ws_net_profit
FROM tpcds.web_sales ws
JOIN tpcds.time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
JOIN tpcds.item i ON ws.ws_item_sk = i.i_item_sk
JOIN tpcds.customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
WHERE td.t_hour BETWEEN 9 AND 17
  AND td.t_am_pm = 'PM'
  AND ca.ca_state IN ('CA','NY','TX'))
ORDER BY sale_date_sk, sales_channel
