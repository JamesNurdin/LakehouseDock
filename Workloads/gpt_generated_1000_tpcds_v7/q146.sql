WITH sales_agg AS (
    SELECT
        s.s_store_sk,
        s.s_store_name,
        wsite.web_name,
        cp.cp_department,
        SUM(ss.ss_ext_sales_price) AS total_store_sales,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        SUM(ss.ss_net_profit) AS total_store_profit,
        SUM(ws.ws_net_profit) AS total_web_profit,
        SUM(sr.sr_return_amt) AS total_store_returns,
        SUM(cr.cr_return_amount) AS total_catalog_returns,
        SUM(wr.wr_return_amt) AS total_web_returns,
        (SUM(ss.ss_ext_sales_price) + SUM(ws.ws_ext_sales_price)
         - COALESCE(SUM(sr.sr_return_amt), 0)
         - COALESCE(SUM(cr.cr_return_amount), 0)
         - COALESCE(SUM(wr.wr_return_amt), 0)) AS net_sales
    FROM store_sales ss
    JOIN customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    LEFT JOIN store_returns sr
        ON sr.sr_ticket_number = ss.ss_ticket_number
        AND sr.sr_customer_sk = c.c_customer_sk
    LEFT JOIN catalog_returns cr
        ON cr.cr_refunded_customer_sk = c.c_customer_sk
    LEFT JOIN call_center cc
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
    LEFT JOIN catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    LEFT JOIN ship_mode sm_cr
        ON cr.cr_ship_mode_sk = sm_cr.sm_ship_mode_sk
    LEFT JOIN warehouse wh_cr
        ON cr.cr_warehouse_sk = wh_cr.w_warehouse_sk
    LEFT JOIN web_sales ws
        ON ws.ws_bill_customer_sk = c.c_customer_sk
    LEFT JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN web_site wsite
        ON ws.ws_web_site_sk = wsite.web_site_sk
    LEFT JOIN ship_mode sm_ws
        ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
    LEFT JOIN warehouse wh_ws
        ON ws.ws_warehouse_sk = wh_ws.w_warehouse_sk
    LEFT JOIN web_returns wr
        ON wr.wr_order_number = ws.ws_order_number
        AND wr.wr_refunded_customer_sk = c.c_customer_sk
    WHERE s.s_state = 'CA'
      AND cc.cc_country = 'United States'
      AND wp.wp_autogen_flag = 'Y'
      AND wsite.web_rec_start_date >= DATE '2001-01-01'
      AND cp.cp_department = 'Electronics'
    GROUP BY ROLLUP (s.s_store_sk, s.s_store_name, wsite.web_name, cp.cp_department)
)
SELECT
    a.s_store_name,
    a.web_name,
    a.cp_department,
    a.total_store_sales,
    a.total_web_sales,
    a.net_sales,
    ROW_NUMBER() OVER (ORDER BY a.net_sales DESC) AS net_sales_rank,
    (
        SELECT AVG(ss2.ss_ext_sales_price)
        FROM store_sales ss2
        WHERE ss2.ss_store_sk = a.s_store_sk
    ) AS avg_store_sales
FROM sales_agg a
LEFT JOIN store s
    ON a.s_store_sk = s.s_store_sk
ORDER BY net_sales_rank
LIMIT 100
