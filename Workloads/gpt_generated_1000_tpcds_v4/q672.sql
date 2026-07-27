WITH filtered_web_sales AS (
    SELECT
        ws.ws_order_number,
        ws.ws_sold_date_sk,
        ws.ws_ship_date_sk,
        ws.ws_bill_hdemo_sk,
        ws.ws_ship_hdemo_sk,
        ws.ws_bill_addr_sk,
        ws.ws_ship_addr_sk,
        ws.ws_web_page_sk,
        ws.ws_web_site_sk,
        ws.ws_ship_mode_sk,
        ws.ws_net_paid,
        ws.ws_ext_discount_amt,
        ws.ws_net_profit,
        ws.ws_quantity,
        ws.ws_net_paid_inc_tax
    FROM tpcds.web_sales ws
    WHERE ws.ws_quantity > 5
      AND ws.ws_net_paid > 100
      AND ws.ws_sold_date_sk IN (
          SELECT d.d_date_sk
          FROM tpcds.date_dim d
          WHERE d.d_year = 2001
            AND d.d_month_seq BETWEEN 1200 AND 1211
      )
),
joined_data AS (
    SELECT
        d_sold.d_year,
        sm.sm_carrier,
        cc.cc_state,
        ca_bill.ca_zip,
        wp.wp_type,
        ws.ws_order_number,
        ws.ws_net_paid,
        ws.ws_ext_discount_amt,
        ws.ws_net_profit,
        wr.wr_return_tax
    FROM filtered_web_sales ws
    JOIN tpcds.date_dim d_sold
        ON ws.ws_sold_date_sk = d_sold.d_date_sk
    JOIN tpcds.date_dim d_ship
        ON ws.ws_ship_date_sk = d_ship.d_date_sk
    JOIN tpcds.household_demographics hd_bill
        ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN tpcds.household_demographics hd_ship
        ON ws.ws_ship_hdemo_sk = hd_ship.hd_demo_sk
    JOIN tpcds.customer_address ca_bill
        ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
    JOIN tpcds.customer_address ca_ship
        ON ws.ws_ship_addr_sk = ca_ship.ca_address_sk
    JOIN tpcds.web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN tpcds.web_site wsit
        ON ws.ws_web_site_sk = wsit.web_site_sk
    JOIN tpcds.ship_mode sm
        ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    LEFT JOIN tpcds.web_returns wr
        ON ws.ws_order_number = wr.wr_order_number
    LEFT JOIN tpcds.catalog_returns cr
        ON d_sold.d_date_sk = cr.cr_returned_date_sk
    LEFT JOIN tpcds.call_center cc
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
    WHERE sm.sm_carrier = 'UPS'
      AND cc.cc_state = 'CA'
      AND ca_bill.ca_zip LIKE '75%'
      AND wp.wp_type = 'home'
      AND (wr.wr_return_tax IS NULL OR wr.wr_return_tax > 10)
)
SELECT
    jd.d_year,
    jd.sm_carrier,
    jd.cc_state,
    COUNT(DISTINCT jd.ws_order_number) AS order_cnt,
    SUM(jd.ws_net_paid) AS total_net_paid,
    AVG(jd.ws_ext_discount_amt) AS avg_discount,
    MIN(jd.ws_net_profit) AS min_profit,
    MAX(jd.ws_net_profit) AS max_profit
FROM joined_data jd
GROUP BY jd.d_year, jd.sm_carrier, jd.cc_state
ORDER BY total_net_paid DESC
LIMIT 100
