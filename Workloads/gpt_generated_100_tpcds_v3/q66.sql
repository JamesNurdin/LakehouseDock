WITH ws AS (
    SELECT *
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk BETWEEN 2450000 AND 2452000
)
SELECT
    c.c_customer_id,
    ca.ca_city,
    cd.cd_gender,
    hd.hd_income_band_sk,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    s.s_store_name,
    r.r_reason_desc,
    sm.sm_type,
    cp.cp_department,
    wp.wp_url,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    SUM(sr.sr_refunded_cash) AS total_refunds,
    COUNT(DISTINCT ws.ws_order_number) AS order_cnt
FROM ws
JOIN date_dim d_sold
    ON ws.ws_sold_date_sk = d_sold.d_date_sk
JOIN time_dim t_sold
    ON ws.ws_sold_time_sk = t_sold.t_time_sk
JOIN customer c
    ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN customer_demographics cd
    ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd
    ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN customer_address ca
    ON ws.ws_bill_addr_sk = ca.ca_address_sk
JOIN ship_mode sm
    ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN catalog_page cp
    ON cp.cp_start_date_sk = d_sold.d_date_sk
JOIN store_returns sr
    ON sr.sr_customer_sk = c.c_customer_sk
JOIN date_dim d_return
    ON sr.sr_returned_date_sk = d_return.d_date_sk
JOIN time_dim t_return
    ON sr.sr_return_time_sk = t_return.t_time_sk
JOIN store s
    ON sr.sr_store_sk = s.s_store_sk
JOIN reason r
    ON sr.sr_reason_sk = r.r_reason_sk
JOIN customer_demographics cd_ret
    ON sr.sr_cdemo_sk = cd_ret.cd_demo_sk
JOIN household_demographics hd_ret
    ON sr.sr_hdemo_sk = hd_ret.hd_demo_sk
JOIN customer_address ca_ret
    ON sr.sr_addr_sk = ca_ret.ca_address_sk
WHERE d_sold.d_year = 1999
  AND sm.sm_type = 'AIR'
  AND cd.cd_gender = 'M'
  AND EXISTS (
        SELECT 1
        FROM web_page wp2
        WHERE wp2.wp_customer_sk = c.c_customer_sk
          AND wp2.wp_type = 'HOME'
    )
GROUP BY
    c.c_customer_id,
    ca.ca_city,
    cd.cd_gender,
    hd.hd_income_band_sk,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    s.s_store_name,
    r.r_reason_desc,
    sm.sm_type,
    cp.cp_department,
    wp.wp_url
HAVING SUM(ws.ws_ext_sales_price) > 10000
ORDER BY total_sales DESC
LIMIT 100
