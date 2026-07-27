WITH sales_joined AS (
    SELECT
        ws.ws_order_number,
        ws.ws_ext_sales_price,
        ws.ws_net_profit,
        ws.ws_list_price,
        ws.ws_coupon_amt,
        wsit.web_name,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        cd.cd_gender,
        cd.cd_marital_status
    FROM web_sales ws
    INNER JOIN customer c
        ON ws.ws_bill_customer_sk = c.c_customer_sk
    INNER JOIN customer_address ca
        ON ws.ws_bill_addr_sk = ca.ca_address_sk
    INNER JOIN customer_demographics cd
        ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    INNER JOIN household_demographics hd
        ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    INNER JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    INNER JOIN web_site wsit
        ON ws.ws_web_site_sk = wsit.web_site_sk
    WHERE ib.ib_upper_bound >= 150000
      AND ws.ws_list_price > 100.00
      AND ws.ws_coupon_amt = 0.00
      AND cd.cd_gender = 'M'
      AND ca.ca_state = 'CA'
)
SELECT
    web_name,
    ib_lower_bound,
    ib_upper_bound,
    cd_gender,
    COUNT(DISTINCT ws_order_number) AS order_cnt,
    SUM(ws_ext_sales_price) AS total_sales,
    AVG(ws_net_profit) AS avg_profit,
    CASE
        WHEN SUM(ws_ext_sales_price) > 100000 THEN 'High'
        ELSE 'Low'
    END AS sales_category
FROM sales_joined
GROUP BY ROLLUP (web_name, ib_lower_bound, ib_upper_bound, cd_gender)
ORDER BY
    web_name,
    ib_lower_bound,
    cd_gender
