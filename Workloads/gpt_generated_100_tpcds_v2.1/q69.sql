WITH distinct_items AS (
    SELECT DISTINCT i.i_item_sk
    FROM item i
    JOIN web_sales ws_c ON ws_c.ws_item_sk = i.i_item_sk
    WHERE ws_c.ws_net_paid > 2000
)
SELECT
    i.i_brand,
    i.i_category,
    wsit.web_name,
    hd.hd_buy_potential,
    COUNT(DISTINCT ss.ss_ticket_number) AS distinct_store_tickets,
    SUM(ss.ss_net_paid) AS total_store_net_paid,
    AVG(cs.cs_net_profit) AS avg_catalog_net_profit,
    MIN(wr.wr_return_amt) AS min_web_return_amt,
    MAX(cr.cr_refunded_cash) AS max_refunded_cash
FROM item i
JOIN distinct_items di ON i.i_item_sk = di.i_item_sk
JOIN store_sales ss ON ss.ss_item_sk = i.i_item_sk
JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk
    AND sr.sr_ticket_number = ss.ss_ticket_number
JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
JOIN catalog_sales cs ON cs.cs_item_sk = i.i_item_sk
JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN catalog_returns cr ON cr.cr_item_sk = i.i_item_sk
    AND cr.cr_order_number = cs.cs_order_number
JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
JOIN web_site wsit ON ws.ws_web_site_sk = wsit.web_site_sk
JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk
    AND wr.wr_order_number = ws.ws_order_number
WHERE
    wsit.web_name = 'site_5'
    AND cc.cc_name = 'Call Center 1'
    AND wr.wr_returned_time_sk IN (74891, 30553)
    AND ss.ss_coupon_amt > 1000
    AND EXISTS (
        SELECT 1
        FROM catalog_sales cs2
        WHERE cs2.cs_item_sk = i.i_item_sk
          AND cs2.cs_net_profit > 5000
    )
GROUP BY
    i.i_brand,
    i.i_category,
    wsit.web_name,
    hd.hd_buy_potential
ORDER BY total_store_net_paid DESC
LIMIT 100
