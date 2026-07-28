WITH avg_warehouse_profit AS (
   SELECT
       w.w_warehouse_sk,
       AVG(cs.cs_net_profit) AS avg_profit
   FROM catalog_sales cs
   JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
   GROUP BY w.w_warehouse_sk
)
SELECT
    cp.cp_catalog_page_id,
    sm.sm_type,
    w.w_warehouse_name,
    hd.hd_income_band_sk,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
    SUM(cs.cs_net_paid) AS total_net_paid,
    SUM(cs.cs_net_profit) AS total_net_profit,
    SUM(CASE WHEN sr.sr_return_quantity > 0 THEN sr.sr_refunded_cash ELSE 0 END) AS total_refunded_cash,
    AVG(ws.ws_net_paid) AS avg_web_net_paid,
    ROW_NUMBER() OVER (PARTITION BY cp.cp_catalog_page_id ORDER BY SUM(cs.cs_net_profit) DESC) AS profit_rank,
    CASE
        WHEN SUM(cs.cs_net_profit) > 50000 THEN 'HIGH'
        WHEN SUM(cs.cs_net_profit) BETWEEN 20000 AND 50000 THEN 'MEDIUM'
        ELSE 'LOW'
    END AS profit_category,
    awp.avg_profit AS warehouse_avg_profit,
    (
        SELECT COUNT(*)
        FROM store_returns sr2
        WHERE sr2.sr_reason_sk = r_sr.r_reason_sk
    ) AS reason_return_cnt
FROM catalog_sales cs
JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN customer cust_bill ON cs.cs_bill_customer_sk = cust_bill.c_customer_sk
JOIN customer cust_ship ON cs.cs_ship_customer_sk = cust_ship.c_customer_sk
JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
-- store_sales joins via the billing customer dimension
JOIN store_sales ss ON ss.ss_customer_sk = cust_bill.c_customer_sk
JOIN household_demographics hd_ss ON ss.ss_hdemo_sk = hd_ss.hd_demo_sk
JOIN customer_address ca_ss ON ss.ss_addr_sk = ca_ss.ca_address_sk
LEFT JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
LEFT JOIN reason r_sr ON sr.sr_reason_sk = r_sr.r_reason_sk
-- web_sales joins via the same billing customer dimension
JOIN web_sales ws ON ws.ws_bill_customer_sk = cust_bill.c_customer_sk
JOIN household_demographics hd_ws ON ws.ws_bill_hdemo_sk = hd_ws.hd_demo_sk
JOIN customer_address ca_ws ON ws.ws_bill_addr_sk = ca_ws.ca_address_sk
LEFT JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
LEFT JOIN reason r_wr ON wr.wr_reason_sk = r_wr.r_reason_sk
LEFT JOIN avg_warehouse_profit awp ON awp.w_warehouse_sk = w.w_warehouse_sk
WHERE sm.sm_type = 'EXPRESS'
  AND hd.hd_income_band_sk = 5
GROUP BY
    cp.cp_catalog_page_id,
    sm.sm_type,
    w.w_warehouse_name,
    hd.hd_income_band_sk,
    awp.avg_profit,
    r_sr.r_reason_sk
HAVING SUM(cs.cs_net_paid) > 10000
ORDER BY total_net_profit DESC
LIMIT 100
