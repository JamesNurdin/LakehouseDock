WITH inv_agg AS (
    SELECT
        inv_item_sk,
        inv_warehouse_sk,
        SUM(inv_quantity_on_hand) AS total_qty_on_hand
    FROM inventory
    GROUP BY inv_item_sk, inv_warehouse_sk
)
SELECT
    s.s_store_name,
    we.web_name,
    i.i_product_name,
    SUM(ss.ss_net_profit) AS store_net_profit,
    SUM(ws.ws_net_profit) AS web_net_profit,
    COUNT(DISTINCT c.c_customer_id) AS unique_customers,
    inv_agg.total_qty_on_hand,
    ib.ib_upper_bound,
    CASE WHEN EXISTS (
            SELECT 1
            FROM store_returns sr2
            WHERE sr2.sr_item_sk = i.i_item_sk
              AND sr2.sr_return_amt > 1000
        ) THEN 'High Returns'
        ELSE 'Low Returns'
    END AS return_level
FROM store_sales ss
JOIN item i                         ON ss.ss_item_sk = i.i_item_sk
JOIN customer c                     ON ss.ss_customer_sk = c.c_customer_sk
JOIN household_demographics hd      ON ss.ss_hdemo_sk = hd.hd_demo_sk
JOIN customer_address ca            ON ss.ss_addr_sk = ca.ca_address_sk
JOIN store s                        ON ss.ss_store_sk = s.s_store_sk
JOIN store_returns sr               ON sr.sr_ticket_number = ss.ss_ticket_number
JOIN reason r                       ON sr.sr_reason_sk = r.r_reason_sk
JOIN web_sales ws                  ON ws.ws_item_sk = i.i_item_sk
JOIN customer c_bill                ON ws.ws_bill_customer_sk = c_bill.c_customer_sk
JOIN household_demographics hd_bill ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
JOIN customer_address ca_bill       ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
JOIN web_page wp                    ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN web_site we                    ON ws.ws_web_site_sk = we.web_site_sk
JOIN ship_mode sm                  ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse wh                  ON ws.ws_warehouse_sk = wh.w_warehouse_sk
JOIN inv_agg ON inv_agg.inv_item_sk = i.i_item_sk
               AND inv_agg.inv_warehouse_sk = wh.w_warehouse_sk
JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
-- additional joins re‑using dimensions via different aliases
JOIN household_demographics hd_cur ON c.c_current_hdemo_sk = hd_cur.hd_demo_sk
JOIN customer_address ca_cur       ON c.c_current_addr_sk = ca_cur.ca_address_sk
WHERE i.i_current_price > 50
GROUP BY
    s.s_store_name,
    we.web_name,
    i.i_product_name,
    inv_agg.total_qty_on_hand,
    ib.ib_upper_bound,
    CASE WHEN EXISTS (
            SELECT 1
            FROM store_returns sr2
            WHERE sr2.sr_item_sk = i.i_item_sk
              AND sr2.sr_return_amt > 1000
        ) THEN 'High Returns'
        ELSE 'Low Returns'
    END
ORDER BY store_net_profit DESC
LIMIT 100
