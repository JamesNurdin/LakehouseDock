WITH base_sales AS (
    SELECT
        ss.ss_store_sk,
        ss.ss_item_sk,
        ss.ss_ticket_number,
        ss.ss_sold_date_sk,
        ss.ss_quantity,
        ss.ss_net_profit,
        ss.ss_hdemo_sk,
        ss.ss_addr_sk,
        s.s_store_name,
        hd.hd_income_band_sk,
        ca.ca_state
    FROM store_sales ss
    JOIN store s               ON ss.ss_store_sk   = s.s_store_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca   ON ss.ss_addr_sk   = ca.ca_address_sk
)
SELECT
    bs.s_store_name,
    we.web_name,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    COUNT(DISTINCT bs.ss_ticket_number)        AS unique_sales,
    SUM(bs.ss_net_profit)                      AS store_profit,
    SUM(cs.cs_ext_sales_price)                 AS catalog_rev,
    SUM(ws.ws_ext_sales_price)                 AS web_rev,
    (SELECT AVG(ss2.ss_net_profit) FROM store_sales ss2) AS avg_store_profit
FROM base_sales bs
LEFT JOIN store_returns sr
    ON bs.ss_ticket_number = sr.sr_ticket_number
LEFT JOIN reason r
    ON sr.sr_reason_sk = r.r_reason_sk
JOIN income_band ib
    ON bs.hd_income_band_sk = ib.ib_income_band_sk
JOIN catalog_sales cs
    ON cs.cs_bill_hdemo_sk = bs.ss_hdemo_sk
JOIN call_center cc
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN warehouse w
    ON cs.cs_warehouse_sk = w.w_warehouse_sk
LEFT JOIN inventory inv
    ON inv.inv_warehouse_sk = w.w_warehouse_sk
JOIN web_sales ws
    ON ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN web_site we
    ON ws.ws_web_site_sk = we.web_site_sk
JOIN household_demographics hd_ws_bill
    ON ws.ws_bill_hdemo_sk = hd_ws_bill.hd_demo_sk
JOIN customer_address ca_ws_bill
    ON ws.ws_bill_addr_sk = ca_ws_bill.ca_address_sk
WHERE ib.ib_upper_bound <= 80000
GROUP BY GROUPING SETS (
    (bs.s_store_name, we.web_name, ib.ib_lower_bound, ib.ib_upper_bound),
    (bs.s_store_name, we.web_name),
    (bs.s_store_name),
    (we.web_name),
    ()
)
ORDER BY store_profit DESC
LIMIT 100
