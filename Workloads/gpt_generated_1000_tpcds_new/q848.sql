WITH
    store_sales_enhanced AS (
        SELECT
            ss.ss_sold_date_sk,
            ss.ss_sold_time_sk,
            ss.ss_store_sk,
            ss.ss_customer_sk,
            ss.ss_hdemo_sk,
            ss.ss_addr_sk,
            ss.ss_item_sk,
            ss.ss_ticket_number,
            SUM(ss.ss_net_paid)               AS store_net_paid,
            SUM(ss.ss_net_profit)             AS store_net_profit,
            SUM(COALESCE(sr.sr_return_amt, 0)) AS total_return_amount,
            COUNT(*)                           AS sales_transactions
        FROM store_sales ss
        LEFT JOIN store_returns sr
               ON ss.ss_ticket_number = sr.sr_ticket_number
              AND ss.ss_item_sk       = sr.sr_item_sk
        JOIN time_dim t
               ON ss.ss_sold_time_sk = t.t_time_sk
        JOIN customer c
               ON ss.ss_customer_sk = c.c_customer_sk
        JOIN household_demographics hd
               ON ss.ss_hdemo_sk = hd.hd_demo_sk
        JOIN customer_address ca
               ON ss.ss_addr_sk = ca.ca_address_sk
        WHERE t.t_shift = 'first'
        GROUP BY ss.ss_sold_date_sk, ss.ss_sold_time_sk, ss.ss_store_sk,
                 ss.ss_customer_sk, ss.ss_hdemo_sk, ss.ss_addr_sk,
                 ss.ss_item_sk, ss.ss_ticket_number
    ),
    web_sales_enhanced AS (
        SELECT
            ws.ws_sold_date_sk,
            ws.ws_sold_time_sk,
            ws.ws_bill_customer_sk,
            ws.ws_item_sk,
            ws.ws_order_number,
            ws.ws_web_site_sk,
            SUM(ws.ws_net_paid)    AS web_net_paid,
            SUM(ws.ws_net_profit)  AS web_net_profit,
            COUNT(*)                AS web_transactions
        FROM web_sales ws
        JOIN time_dim t
                 ON ws.ws_sold_time_sk = t.t_time_sk
        JOIN customer c
                 ON ws.ws_bill_customer_sk = c.c_customer_sk
        WHERE ws.ws_quantity > 5
        GROUP BY ws.ws_sold_date_sk, ws.ws_sold_time_sk,
                 ws.ws_bill_customer_sk, ws.ws_item_sk,
                 ws.ws_order_number, ws.ws_web_site_sk
    ),
    customers_intersection AS (
        SELECT c.c_customer_sk
        FROM store_sales ss
        JOIN customer c
          ON ss.ss_customer_sk = c.c_customer_sk
        WHERE c.c_preferred_cust_flag = 'Y'
        INTERSECT
        SELECT cr.cr_returning_customer_sk
        FROM catalog_returns cr
        WHERE cr.cr_return_amount > 500
    )
SELECT
    s.s_store_name,
    c.c_first_name,
    c.c_last_name,
    ca.ca_city,
    hd.hd_buy_potential,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    sm.sm_type,
    COALESCE(ss_en.store_net_paid, 0)           AS store_net_paid,
    COALESCE(ws_en.web_net_paid, 0)            AS web_net_paid,
    (SELECT AVG(ws2.ws_net_paid)
       FROM web_sales ws2
       WHERE ws2.ws_quantity > 5)            AS avg_web_net_paid,
    COALESCE(ss_en.sales_transactions, 0) + COALESCE(ws_en.web_transactions, 0) AS total_transactions,
    GREATEST(COALESCE(ss_en.store_net_profit, 0), COALESCE(ws_en.web_net_profit, 0)) AS max_profit
FROM store_sales_enhanced ss_en
FULL OUTER JOIN web_sales_enhanced ws_en
        ON ss_en.ss_sold_time_sk = ws_en.ws_sold_time_sk
JOIN store s
        ON ss_en.ss_store_sk = s.s_store_sk
JOIN customer c
        ON COALESCE(ss_en.ss_customer_sk, ws_en.ws_bill_customer_sk) = c.c_customer_sk
JOIN customer_address ca
        ON ss_en.ss_addr_sk = ca.ca_address_sk
JOIN household_demographics hd
        ON ss_en.ss_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN ship_mode sm
        ON EXISTS (
               SELECT 1
               FROM catalog_returns cr
               WHERE cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
                 AND cr.cr_return_amount > 1000
               LIMIT 1
           )
JOIN catalog_returns cr
        ON cr.cr_call_center_sk = (
               SELECT cc.cc_call_center_sk
               FROM call_center cc
               WHERE cc.cc_state = 'CA'
               LIMIT 1
           )
JOIN call_center cc
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
JOIN web_site ws
        ON ws_en.ws_web_site_sk = ws.web_site_sk
WHERE EXISTS (SELECT 1 FROM customers_intersection ci WHERE ci.c_customer_sk = c.c_customer_sk)
GROUP BY s.s_store_name,
         c.c_first_name,
         c.c_last_name,
         ca.ca_city,
         hd.hd_buy_potential,
         ib.ib_lower_bound,
         ib.ib_upper_bound,
         sm.sm_type,
         ss_en.store_net_paid,
         ws_en.web_net_paid,
         ss_en.sales_transactions,
         ws_en.web_transactions,
         ss_en.store_net_profit,
         ws_en.web_net_profit
ORDER BY store_net_paid DESC
LIMIT 100
