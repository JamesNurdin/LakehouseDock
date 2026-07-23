WITH
    cr_agg AS (
        SELECT
            cr.cr_refunded_customer_sk AS customer_sk,
            SUM(cr.cr_net_loss) AS total_cr_net_loss,
            SUM(cr.cr_return_amount) AS total_cr_return_amount,
            COUNT(*) AS cr_return_cnt
        FROM catalog_returns cr
        JOIN date_dim d_cr ON cr.cr_returned_date_sk = d_cr.d_date_sk
        JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
        JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
        JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
        WHERE d_cr.d_year = 2001
          AND sm.sm_carrier = 'FEDEX'
          AND r.r_reason_desc LIKE '%damaged%'
          AND ca.ca_state = 'TX'
        GROUP BY cr.cr_refunded_customer_sk
    ),
    sr_agg AS (
        SELECT
            sr.sr_customer_sk AS customer_sk,
            SUM(sr.sr_net_loss) AS total_sr_net_loss,
            SUM(sr.sr_return_amt) AS total_sr_return_amt,
            COUNT(*) AS sr_return_cnt
        FROM store_returns sr
        JOIN date_dim d_sr ON sr.sr_returned_date_sk = d_sr.d_date_sk
        JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
        JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
        JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
        WHERE d_sr.d_year = 2001
          AND hd.hd_dep_count > 2
          AND ca.ca_state = 'TX'
        GROUP BY sr.sr_customer_sk
    ),
    ss_agg AS (
        SELECT
            ss.ss_customer_sk AS customer_sk,
            SUM(ss.ss_net_profit) AS total_ss_net_profit,
            SUM(ss.ss_ext_sales_price) AS total_ss_sales,
            COUNT(*) AS ss_cnt
        FROM store_sales ss
        JOIN date_dim d_ss ON ss.ss_sold_date_sk = d_ss.d_date_sk
        JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
        JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
        WHERE d_ss.d_year = 2001
          AND hd.hd_income_band_sk IN (1, 2, 3)
          AND ca.ca_state = 'TX'
        GROUP BY ss.ss_customer_sk
    ),
    ws_agg AS (
        SELECT
            ws.ws_bill_customer_sk AS customer_sk,
            SUM(ws.ws_net_profit) AS total_ws_net_profit,
            SUM(ws.ws_ext_sales_price) AS total_ws_sales,
            COUNT(*) AS ws_cnt
        FROM web_sales ws
        JOIN date_dim d_ws ON ws.ws_sold_date_sk = d_ws.d_date_sk
        JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
        JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
        JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
        JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
        WHERE d_ws.d_year = 2001
          AND sm.sm_carrier = 'FEDEX'
          AND wsite.web_state = 'CA'
          AND ca.ca_state = 'TX'
        GROUP BY ws.ws_bill_customer_sk
    ),
    cust AS (
        SELECT
            c.c_customer_sk,
            c.c_customer_id,
            c.c_first_name,
            c.c_last_name,
            c.c_preferred_cust_flag,
            ca.ca_city AS ca_city,
            ca.ca_state AS ca_state,
            hd.hd_buy_potential AS hd_buy_potential
        FROM customer c
        JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
        JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
        WHERE c.c_preferred_cust_flag = 'Y'
    )
SELECT DISTINCT
    cust.c_customer_id,
    cust.c_first_name,
    cust.c_last_name,
    cust.ca_city,
    cust.ca_state,
    cust.hd_buy_potential,
    COALESCE(ss_agg.total_ss_net_profit, 0) AS store_net_profit,
    COALESCE(ws_agg.total_ws_net_profit, 0) AS web_net_profit,
    COALESCE(cr_agg.total_cr_net_loss, 0) AS catalog_net_loss,
    COALESCE(sr_agg.total_sr_net_loss, 0) AS store_return_net_loss,
    (COALESCE(ss_agg.total_ss_net_profit, 0) + COALESCE(ws_agg.total_ws_net_profit, 0)
        - COALESCE(cr_agg.total_cr_net_loss, 0) - COALESCE(sr_agg.total_sr_net_loss, 0)) AS overall_contribution,
    ROW_NUMBER() OVER (ORDER BY (COALESCE(ss_agg.total_ss_net_profit, 0) + COALESCE(ws_agg.total_ws_net_profit, 0)
        - COALESCE(cr_agg.total_cr_net_loss, 0) - COALESCE(sr_agg.total_sr_net_loss, 0)) DESC) AS profit_rank
FROM cust
LEFT JOIN ss_agg ON cust.c_customer_sk = ss_agg.customer_sk
LEFT JOIN ws_agg ON cust.c_customer_sk = ws_agg.customer_sk
LEFT JOIN cr_agg ON cust.c_customer_sk = cr_agg.customer_sk
LEFT JOIN sr_agg ON cust.c_customer_sk = sr_agg.customer_sk
ORDER BY profit_rank
LIMIT 100
