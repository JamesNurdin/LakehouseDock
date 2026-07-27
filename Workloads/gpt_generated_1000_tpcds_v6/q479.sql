WITH joined AS (
    SELECT
        ws.ws_ext_sales_price,
        ws.ws_net_profit,
        ws.ws_order_number,
        ws.ws_ext_discount_amt,
        d.d_year,
        ca.ca_state,
        hd.hd_buy_potential,
        hd.hd_vehicle_count,
        ib.ib_upper_bound,
        wp.wp_char_count
    FROM tpcds.web_sales ws
    JOIN tpcds.date_dim d
        ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN tpcds.web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN tpcds.customer_address ca
        ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN tpcds.household_demographics hd
        ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN tpcds.income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE d.d_year = 2001
      AND ca.ca_state = 'CA'
      AND hd.hd_vehicle_count >= 2
      AND ib.ib_upper_bound <= 120000
      AND wp.wp_char_count > (
            SELECT AVG(wp2.wp_char_count)
            FROM tpcds.web_page wp2
            WHERE wp2.wp_type = 'content'
        )
)
SELECT
    ca_state,
    d_year,
    hd_buy_potential,
    SUM(ws_ext_sales_price) AS total_sales,
    AVG(ws_net_profit) AS avg_profit,
    COUNT(DISTINCT ws_order_number) AS order_cnt,
    MIN(ws_ext_discount_amt) AS min_discount,
    MAX(ws_ext_discount_amt) AS max_discount,
    (SELECT MAX(ib3.ib_upper_bound)
     FROM tpcds.income_band ib3
     WHERE ib3.ib_lower_bound >= 50000) AS max_upper_income
FROM joined
GROUP BY ca_state, d_year, hd_buy_potential
ORDER BY total_sales DESC
LIMIT 100
