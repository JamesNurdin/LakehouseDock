WITH sales_data AS (
    SELECT
        s.s_store_name AS s_store_name,
        s.s_state,
        cr_reason.r_reason_desc AS catalog_return_reason,
        sr_reason.r_reason_desc AS store_return_reason,
        wr_reason.r_reason_desc AS web_return_reason,
        t.t_hour,
        ca.ca_state,
        hd.hd_income_band_sk,
        sm.sm_type,
        ss.ss_net_paid,
        ss.ss_net_profit,
        ss.ss_ticket_number,
        cs.cs_sales_price,
        cr.cr_return_amount,
        sr.sr_return_amt,
        wr.wr_return_amt,
        ws.ws_net_paid AS web_net_paid,
        wp.wp_link_count
    FROM store_sales ss
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN time_dim t
        ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN catalog_sales cs
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
       AND cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
       AND cr.cr_item_sk = cs.cs_item_sk
    JOIN reason cr_reason
        ON cr.cr_reason_sk = cr_reason.r_reason_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN store_returns sr
        ON sr.sr_ticket_number = ss.ss_ticket_number
       AND sr.sr_item_sk = ss.ss_item_sk
    JOIN reason sr_reason
        ON sr.sr_reason_sk = sr_reason.r_reason_sk
    JOIN web_sales ws
        ON ws.ws_item_sk = ss.ss_item_sk
    JOIN web_returns wr
        ON wr.wr_order_number = ws.ws_order_number
       AND wr.wr_item_sk = ws.ws_item_sk
    JOIN reason wr_reason
        ON wr.wr_reason_sk = wr_reason.r_reason_sk
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE ca.ca_state = 'CA'
      AND t.t_hour = 14
      AND hd.hd_income_band_sk = 5
      AND wp.wp_link_count > 10
      AND cs.cs_sales_price > (
          SELECT AVG(cs2.cs_sales_price)
          FROM catalog_sales cs2
          WHERE cs2.cs_sold_date_sk = 2452000
      )
      AND EXISTS (
          SELECT 1
          FROM store_returns sr2
          WHERE sr2.sr_ticket_number = ss.ss_ticket_number
            AND sr2.sr_return_amt > 0
      )
)
SELECT
    s_store_name,
    catalog_return_reason,
    SUM(ss_net_paid) AS total_store_net_paid,
    COUNT(DISTINCT ss_ticket_number) AS cnt_tickets,
    AVG(web_net_paid) AS avg_web_net_paid,
    SUM(cr_return_amount) AS total_catalog_returns,
    SUM(sr_return_amt) AS total_store_returns,
    SUM(wr_return_amt) AS total_web_returns
FROM sales_data
GROUP BY GROUPING SETS (
    (s_store_name, catalog_return_reason),
    (s_store_name),
    (catalog_return_reason)
)
ORDER BY total_store_net_paid DESC
LIMIT 100
