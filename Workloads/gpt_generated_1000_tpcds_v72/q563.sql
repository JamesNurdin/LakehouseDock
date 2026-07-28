WITH aggregated AS (
    SELECT
        i.i_category,
        sm.sm_type,
        ib.ib_upper_bound,
        SUM(ws.ws_net_paid)          AS total_web_paid,
        SUM(ss.ss_net_paid)          AS total_store_paid,
        COUNT(DISTINCT ws.ws_order_number) AS web_orders,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_tickets
    FROM store_sales ss
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    JOIN customer c_ss
        ON ss.ss_customer_sk = c_ss.c_customer_sk
    JOIN customer_address ca_ss
        ON ss.ss_addr_sk = ca_ss.ca_address_sk
    JOIN customer_demographics cd_ss
        ON ss.ss_cdemo_sk = cd_ss.cd_demo_sk
    JOIN household_demographics hd_ss
        ON ss.ss_hdemo_sk = hd_ss.hd_demo_sk
    JOIN income_band ib
        ON hd_ss.hd_income_band_sk = ib.ib_income_band_sk
    JOIN web_sales ws
        ON ws.ws_item_sk = i.i_item_sk
       AND ws.ws_bill_customer_sk = c_ss.c_customer_sk
    JOIN customer c_bill
        ON ws.ws_bill_customer_sk = c_bill.c_customer_sk
    JOIN customer_address ca_bill
        ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
    JOIN customer c_ship
        ON ws.ws_ship_customer_sk = c_ship.c_customer_sk
    JOIN customer_address ca_ship
        ON ws.ws_ship_addr_sk = ca_ship.ca_address_sk
    JOIN ship_mode sm
        ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w
        ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN web_site site
        ON ws.ws_web_site_sk = site.web_site_sk
    JOIN web_returns wr
        ON wr.wr_order_number = ws.ws_order_number
       AND wr.wr_item_sk = i.i_item_sk
    GROUP BY GROUPING SETS (
        (i.i_category, sm.sm_type, ib.ib_upper_bound),
        (i.i_category, sm.sm_type),
        (i.i_category),
        ()
    )
)
SELECT
    ag.i_category,
    ag.sm_type,
    ag.ib_upper_bound,
    ag.total_web_paid,
    ag.total_store_paid,
    ag.web_orders,
    ag.store_tickets,
    -- correlated sub‑query: average web net paid for the same item category
    (SELECT AVG(ws2.ws_net_paid)
       FROM web_sales ws2
       JOIN item i2 ON ws2.ws_item_sk = i2.i_item_sk
       WHERE i2.i_category = ag.i_category) AS avg_web_paid_for_category,
    -- window function: rank categories by total web revenue
    ROW_NUMBER() OVER (PARTITION BY ag.i_category ORDER BY ag.total_web_paid DESC) AS category_rank
FROM aggregated ag
WHERE ag.total_web_paid > 0
ORDER BY ag.i_category, ag.sm_type, ag.total_web_paid DESC
LIMIT 100
