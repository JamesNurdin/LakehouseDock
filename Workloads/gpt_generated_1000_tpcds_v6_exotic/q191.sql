WITH filtered_customer AS (
    SELECT *
    FROM customer c
    WHERE c.c_preferred_cust_flag = 'Y'
),
filtered_address AS (
    SELECT *
    FROM customer_address ca
    WHERE ca.ca_state = 'CA'
),
filtered_hd AS (
    SELECT *
    FROM household_demographics hd
    WHERE hd.hd_buy_potential = '5001-10000'
      AND EXISTS (
          SELECT 1
          FROM income_band ib
          WHERE ib.ib_income_band_sk = hd.hd_income_band_sk
            AND ib.ib_upper_bound <= 150000
      )
),
filtered_ship_mode AS (
    SELECT *
    FROM ship_mode sm
    WHERE sm.sm_contract = 'yVfotg7Tio3MVhBg6Bkn'
),
filtered_store AS (
    SELECT *
    FROM store s
    WHERE s.s_state = 'TX'
),
filtered_web_site AS (
    SELECT *
    FROM web_site wsit
    WHERE wsit.web_open_date_sk > 2450000
)
SELECT
    s.s_store_name,
    wsit.web_name,
    sm.sm_type,
    td_s.t_hour,
    COUNT(DISTINCT ws.ws_order_number)            AS num_orders,
    SUM(ws.ws_ext_sales_price)                     AS total_sales,
    SUM(sr.sr_return_amt)                          AS total_store_return_amt,
    SUM(wr.wr_return_amt)                          AS total_web_return_amt,
    AVG(hd.hd_dep_count)                           AS avg_dep_count,
    MIN(ws.ws_net_profit)                          AS min_net_profit,
    MAX(ws.ws_net_profit)                          AS max_net_profit
FROM store_returns sr
INNER JOIN time_dim td_s
        ON sr.sr_return_time_sk = td_s.t_time_sk
INNER JOIN filtered_customer c
        ON sr.sr_customer_sk = c.c_customer_sk
INNER JOIN filtered_hd hd
        ON sr.sr_hdemo_sk = hd.hd_demo_sk
INNER JOIN filtered_address ca
        ON sr.sr_addr_sk = ca.ca_address_sk
INNER JOIN filtered_store s
        ON sr.sr_store_sk = s.s_store_sk
INNER JOIN reason r_sr
        ON sr.sr_reason_sk = r_sr.r_reason_sk
-- join to the web‑sales fact via the same customer
INNER JOIN web_sales ws
        ON ws.ws_bill_customer_sk = c.c_customer_sk
INNER JOIN time_dim td_ws
        ON ws.ws_sold_time_sk = td_ws.t_time_sk
INNER JOIN filtered_ship_mode sm
        ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
INNER JOIN warehouse w
        ON ws.ws_warehouse_sk = w.w_warehouse_sk
INNER JOIN filtered_web_site wsit
        ON ws.ws_web_site_sk = wsit.web_site_sk
INNER JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
-- web returns linked to the same order/item
INNER JOIN web_returns wr
        ON wr.wr_order_number = ws.ws_order_number
       AND wr.wr_item_sk = ws.ws_item_sk
INNER JOIN reason r_wr
        ON wr.wr_reason_sk = r_wr.r_reason_sk
INNER JOIN time_dim td_wr
        ON wr.wr_returned_time_sk = td_wr.t_time_sk
INNER JOIN customer c_wr_refunded
        ON wr.wr_refunded_customer_sk = c_wr_refunded.c_customer_sk
INNER JOIN household_demographics hd_wr
        ON wr.wr_refunded_hdemo_sk = hd_wr.hd_demo_sk
INNER JOIN customer_address ca_wr
        ON wr.wr_refunded_addr_sk = ca_wr.ca_address_sk
INNER JOIN web_page wp_wr
        ON wr.wr_web_page_sk = wp_wr.wp_web_page_sk
WHERE td_s.t_hour BETWEEN 9 AND 17
GROUP BY
    s.s_store_name,
    wsit.web_name,
    sm.sm_type,
    td_s.t_hour
ORDER BY total_sales DESC
LIMIT 100
