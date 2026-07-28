WITH sales_agg AS (
    SELECT
        ca_cur.ca_state AS state,
        CONCAT(CAST(ib.ib_lower_bound AS varchar), '-', CAST(ib.ib_upper_bound AS varchar)) AS income_range,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(sr.sr_return_amt) AS total_store_returns,
        SUM(cr.cr_return_amount) AS total_catalog_returns,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        SUM(ss.ss_net_profit) + SUM(ws.ws_net_profit) AS total_profit
    FROM tpcds.customer c
    JOIN tpcds.customer_address ca_cur ON c.c_current_addr_sk = ca_cur.ca_address_sk
    JOIN tpcds.household_demographics hd_cur ON c.c_current_hdemo_sk = hd_cur.hd_demo_sk
    JOIN tpcds.income_band ib ON hd_cur.hd_income_band_sk = ib.ib_income_band_sk
    JOIN tpcds.store_sales ss ON ss.ss_customer_sk = c.c_customer_sk
    JOIN tpcds.customer_address ca_ss ON ss.ss_addr_sk = ca_ss.ca_address_sk
    JOIN tpcds.household_demographics hd_ss ON ss.ss_hdemo_sk = hd_ss.hd_demo_sk
    JOIN tpcds.store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
    JOIN tpcds.customer_address ca_sr ON sr.sr_addr_sk = ca_sr.ca_address_sk
    JOIN tpcds.household_demographics hd_sr ON sr.sr_hdemo_sk = hd_sr.hd_demo_sk
    JOIN tpcds.catalog_returns cr ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN tpcds.customer_address ca_cr ON cr.cr_refunded_addr_sk = ca_cr.ca_address_sk
    JOIN tpcds.household_demographics hd_cr ON cr.cr_refunded_hdemo_sk = hd_cr.hd_demo_sk
    JOIN tpcds.web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN tpcds.customer_address ca_ws_bill ON ws.ws_bill_addr_sk = ca_ws_bill.ca_address_sk
    JOIN tpcds.household_demographics hd_ws_bill ON ws.ws_bill_hdemo_sk = hd_ws_bill.hd_demo_sk
    JOIN tpcds.web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN tpcds.customer_address ca_ws_ship ON ws.ws_ship_addr_sk = ca_ws_ship.ca_address_sk
    JOIN tpcds.household_demographics hd_ws_ship ON ws.ws_ship_hdemo_sk = hd_ws_ship.hd_demo_sk
    WHERE ss.ss_list_price > 100
      AND ss.ss_ext_tax BETWEEN 0 AND 50
      AND hd_cur.hd_dep_count >= 5
      AND ib.ib_upper_bound <= 50000
      AND cr.cr_return_amount > 50
      AND ws.ws_net_profit > 0
      AND wp.wp_type = 'Content'
      AND ca_cur.ca_state = 'CA'
    GROUP BY ca_cur.ca_state,
             CONCAT(CAST(ib.ib_lower_bound AS varchar), '-', CAST(ib.ib_upper_bound AS varchar))
)
SELECT
    state,
    income_range,
    SUM(total_sales) AS sum_sales,
    SUM(total_profit) AS sum_profit
FROM sales_agg
WHERE total_sales > (SELECT AVG(total_sales) FROM sales_agg)
GROUP BY ROLLUP(state, income_range)
HAVING SUM(total_sales) IS NOT NULL
ORDER BY state, income_range
