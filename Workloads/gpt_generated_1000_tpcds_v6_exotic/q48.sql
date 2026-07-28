WITH joined_data AS (
    SELECT
        ws.ws_ext_sales_price,
        d_sold.d_date AS sale_date,
        d_sold.d_year,
        c_bill.c_customer_id,
        c_bill.c_first_name,
        c_bill.c_last_name,
        sm.sm_ship_mode_id,
        sm.sm_contract,
        cc.cc_name,
        cc.cc_state,
        cd_bill.cd_gender,
        hd_bill.hd_income_band_sk,
        cp.cp_catalog_page_id,
        cp.cp_department
    FROM web_sales ws
    JOIN date_dim d_sold ON ws.ws_sold_date_sk = d_sold.d_date_sk
    JOIN date_dim d_ship ON ws.ws_ship_date_sk = d_ship.d_date_sk
    JOIN customer c_bill ON ws.ws_bill_customer_sk = c_bill.c_customer_sk
    JOIN customer_demographics cd_bill ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
    JOIN household_demographics hd_bill ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site wsit ON ws.ws_web_site_sk = wsit.web_site_sk
    JOIN call_center cc ON cc.cc_closed_date_sk = d_sold.d_date_sk
    JOIN catalog_page cp ON cp.cp_start_date_sk = d_sold.d_date_sk
    WHERE d_sold.d_year = 2001
      AND ws.ws_ext_sales_price > 5000
      AND sm.sm_contract LIKE 'I3uCelXtjP%'
      AND cc.cc_state = 'CA'
      AND cd_bill.cd_gender = 'M'
      AND hd_bill.hd_income_band_sk BETWEEN 10 AND 15
      AND NOT EXISTS (
          SELECT 1 FROM catalog_page cp2 WHERE cp2.cp_catalog_page_id = cc.cc_call_center_id
      )
)
SELECT
    c_customer_id,
    CONCAT(c_first_name, ' ', c_last_name) AS customer_name,
    sale_date,
    ws_ext_sales_price,
    sm_ship_mode_id,
    cc_name,
    cd_gender,
    hd_income_band_sk,
    SUM(ws_ext_sales_price) OVER (
        PARTITION BY c_customer_id
        ORDER BY sale_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_sales,
    RANK() OVER (
        PARTITION BY c_customer_id
        ORDER BY ws_ext_sales_price DESC
    ) AS sales_rank
FROM joined_data
ORDER BY cumulative_sales DESC
LIMIT 100
