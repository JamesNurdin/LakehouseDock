WITH ss_agg AS (
    SELECT
        ss_customer_sk,
        ss_hdemo_sk,
        ss_item_sk,
        ss_ticket_number,
        SUM(ss_ext_sales_price) AS total_sales,
        SUM(ss_ext_tax) AS total_tax,
        COUNT(*) AS sales_cnt
    FROM store_sales
    WHERE ss_ext_tax > 20
    GROUP BY ss_customer_sk, ss_hdemo_sk, ss_item_sk, ss_ticket_number
)
SELECT
    c.c_customer_id,
    hd.hd_buy_potential,
    SUM(ss_agg.total_sales) AS total_store_sales,
    SUM(sr.sr_return_amt) AS total_store_returns,
    SUM(ws.ws_net_paid) AS total_web_sales,
    AVG(ws.ws_ext_ship_cost) AS avg_ship_cost,
    CASE WHEN SUM(ss_agg.total_sales) > 10000 THEN 'High' ELSE 'Low' END AS sales_category,
    COUNT(DISTINCT ss_agg.ss_ticket_number) AS store_txn_cnt,
    MIN(sm.sm_type) AS ship_mode_type,
    MAX(wp.wp_type) AS web_page_type
FROM ss_agg
INNER JOIN store_returns sr
    ON sr.sr_customer_sk = ss_agg.ss_customer_sk
   AND sr.sr_hdemo_sk = ss_agg.ss_hdemo_sk
   AND sr.sr_ticket_number = ss_agg.ss_ticket_number
   AND sr.sr_item_sk = ss_agg.ss_item_sk
INNER JOIN customer c
    ON c.c_customer_sk = ss_agg.ss_customer_sk
INNER JOIN household_demographics hd
    ON hd.hd_demo_sk = ss_agg.ss_hdemo_sk
INNER JOIN web_sales ws
    ON ws.ws_bill_customer_sk = c.c_customer_sk
   AND ws.ws_bill_hdemo_sk = hd.hd_demo_sk
INNER JOIN ship_mode sm
    ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
INNER JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
INNER JOIN web_site wsite
    ON ws.ws_web_site_sk = wsite.web_site_sk
WHERE
    c.c_preferred_cust_flag = 'Y'
    AND hd.hd_buy_potential = 'HIGH'
    AND ws.ws_net_paid > 500
    AND sr.sr_return_ship_cost > 0
GROUP BY
    c.c_customer_id,
    hd.hd_buy_potential
ORDER BY total_store_sales DESC
LIMIT 100
