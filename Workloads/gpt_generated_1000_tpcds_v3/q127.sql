SELECT
    w.w_warehouse_name,
    w.w_city,
    t.t_hour,
    r.r_reason_desc,
    we.web_name,
    COUNT(DISTINCT cs.cs_order_number) AS catalog_order_cnt,
    COUNT(DISTINCT ws.ws_order_number) AS web_order_cnt,
    SUM(cs.cs_ext_sales_price) AS total_catalog_sales,
    SUM(ws.ws_ext_sales_price) AS total_web_sales,
    SUM(sr.sr_return_amt) AS total_return_amount,
    AVG(cs.cs_net_profit) AS avg_catalog_profit,
    MAX(sr.sr_net_loss) AS max_return_loss,
    (SELECT AVG(cs2.cs_ext_sales_price) FROM catalog_sales cs2) AS avg_catalog_sales_price_overall
FROM store_returns sr
JOIN time_dim t
    ON sr.sr_return_time_sk = t.t_time_sk
JOIN customer_demographics cd
    ON sr.sr_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd
    ON sr.sr_hdemo_sk = hd.hd_demo_sk
JOIN customer_address ca
    ON sr.sr_addr_sk = ca.ca_address_sk
JOIN reason r
    ON sr.sr_reason_sk = r.r_reason_sk
JOIN catalog_sales cs
    ON cs.cs_sold_time_sk = t.t_time_sk
JOIN warehouse w
    ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN web_sales ws
    ON ws.ws_sold_time_sk = t.t_time_sk
    AND ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN web_site we
    ON ws.ws_web_site_sk = we.web_site_sk
WHERE sr.sr_store_credit > 20.00
  AND sr.sr_return_ship_cost < 500.00
  AND cd.cd_marital_status = 'M'
  AND cd.cd_dep_employed_count >= 2
  AND w.w_city = 'Pleasant Valley'
  AND t.t_hour BETWEEN 9 AND 17
  AND cs.cs_item_sk IN (SELECT ws2.ws_item_sk FROM web_sales ws2 WHERE ws2.ws_net_profit > 500)
GROUP BY w.w_warehouse_name,
         w.w_city,
         t.t_hour,
         r.r_reason_desc,
         we.web_name
ORDER BY total_catalog_sales DESC
LIMIT 100
