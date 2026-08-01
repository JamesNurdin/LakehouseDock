WITH filtered_data AS (
    SELECT
        d.d_year AS d_year,
        cc.cc_name AS cc_name,
        sm.sm_type AS sm_type,
        w.w_state AS w_state,
        hd.hd_buy_potential AS hd_buy_potential,
        ss.ss_net_profit AS ss_net_profit,
        ws.ws_net_profit AS ws_net_profit,
        cs.cs_net_profit AS cs_net_profit,
        ss.ss_quantity AS ss_quantity,
        ws.ws_quantity AS ws_quantity,
        cs.cs_quantity AS cs_quantity,
        ss.ss_ext_discount_amt AS ss_ext_discount_amt,
        ws.ws_ext_discount_amt AS ws_ext_discount_amt,
        cs.cs_ext_discount_amt AS cs_ext_discount_amt,
        c.c_customer_id AS c_customer_id
    FROM tpcds.date_dim d
    INNER JOIN tpcds.store_sales ss ON ss.ss_sold_date_sk = d.d_date_sk
    INNER JOIN tpcds.store_returns sr ON sr.sr_returned_date_sk = d.d_date_sk AND sr.sr_ticket_number = ss.ss_ticket_number
    INNER JOIN tpcds.web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
    INNER JOIN tpcds.web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk AND wr.wr_order_number = ws.ws_order_number
    INNER JOIN tpcds.catalog_sales cs ON cs.cs_sold_date_sk = d.d_date_sk
    INNER JOIN tpcds.call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    INNER JOIN tpcds.catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    INNER JOIN tpcds.ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    INNER JOIN tpcds.warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    INNER JOIN tpcds.promotion p ON cs.cs_promo_sk = p.p_promo_sk
    INNER JOIN tpcds.customer c ON ss.ss_customer_sk = c.c_customer_sk
    INNER JOIN tpcds.household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    INNER JOIN tpcds.customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    INNER JOIN tpcds.web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    INNER JOIN tpcds.web_site we ON ws.ws_web_site_sk = we.web_site_sk
    WHERE d.d_year = 2001
      AND d.d_current_month = 'Y'
      AND cc.cc_employees > 4000000
      AND p.p_discount_active = 'Y'
      AND cs.cs_ext_sales_price > 1000
)
SELECT
    d_year,
    cc_name,
    sm_type,
    w_state,
    hd_buy_potential,
    SUM(ss_net_profit) AS total_store_profit,
    SUM(ws_net_profit) AS total_web_profit,
    SUM(cs_net_profit) AS total_catalog_profit,
    SUM(ss_quantity + ws_quantity + cs_quantity) AS total_quantity,
    COUNT(DISTINCT c_customer_id) AS unique_customers,
    AVG(ss_ext_discount_amt) AS avg_store_discount,
    MIN(ss_net_profit) AS min_store_profit,
    MAX(ss_net_profit) AS max_store_profit
FROM filtered_data
GROUP BY d_year, cc_name, sm_type, w_state, hd_buy_potential
ORDER BY total_store_profit DESC
LIMIT 100
