WITH ws_agg AS (
    SELECT
        ws_order_number,
        SUM(ws_net_paid) AS total_ws_net_paid,
        COUNT(*) AS ws_transactions
    FROM web_sales
    GROUP BY ws_order_number
)
SELECT
    cc.cc_name,
    cp.cp_department,
    sm.sm_type,
    td_sold.t_hour,
    CASE WHEN SUM(cs.cs_net_profit) > 0 THEN 'PROFITABLE' ELSE 'LOSS' END AS profit_flag,
    SUM(cs.cs_ext_sales_price) AS catalog_sales_amount,
    SUM(ws_agg.total_ws_net_paid) AS web_sales_total,
    COUNT(DISTINCT cs.cs_order_number) AS num_orders,
    SUM(ws_agg.ws_transactions) AS total_web_transactions
FROM catalog_sales cs
JOIN call_center cc
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm
    ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN time_dim td_sold
    ON cs.cs_sold_time_sk = td_sold.t_time_sk
JOIN customer c_bill
    ON cs.cs_bill_customer_sk = c_bill.c_customer_sk
JOIN customer_address ca_bill
    ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
JOIN customer c_ship
    ON cs.cs_ship_customer_sk = c_ship.c_customer_sk
JOIN customer_address ca_ship
    ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
JOIN store_sales ss
    ON ss.ss_customer_sk = c_bill.c_customer_sk
   AND ss.ss_sold_time_sk = td_sold.t_time_sk
JOIN time_dim td_store
    ON ss.ss_sold_time_sk = td_store.t_time_sk
JOIN web_sales ws
    ON ws.ws_order_number = cs.cs_order_number
JOIN ws_agg
    ON ws.ws_order_number = ws_agg.ws_order_number
JOIN web_returns wr
    ON wr.wr_order_number = ws.ws_order_number
JOIN time_dim td_return
    ON wr.wr_returned_time_sk = td_return.t_time_sk
JOIN web_site wsite
    ON ws.ws_web_site_sk = wsite.web_site_sk
WHERE td_sold.t_hour BETWEEN 8 AND 20
GROUP BY
    cc.cc_name,
    cp.cp_department,
    sm.sm_type,
    td_sold.t_hour
ORDER BY
    catalog_sales_amount DESC
LIMIT 100
