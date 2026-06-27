WITH sales_agg AS (
    SELECT
        cd.cd_gender,
        cd.cd_marital_status,
        hd.hd_income_band_sk,
        ca.ca_city,
        ca.ca_state,
        SUM(cs.cs_net_paid) AS total_net_paid,
        SUM(cs.cs_net_profit) AS total_net_profit,
        COUNT(DISTINCT cs.cs_order_number) AS order_count
    FROM catalog_sales cs
    JOIN date_dim d_sales
        ON cs.cs_sold_date_sk = d_sales.d_date_sk
    JOIN customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd
        ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca
        ON cs.cs_bill_addr_sk = ca.ca_address_sk
    WHERE d_sales.d_year = 2022
    GROUP BY cd.cd_gender, cd.cd_marital_status, hd.hd_income_band_sk, ca.ca_city, ca.ca_state
),
web_page_agg AS (
    SELECT
        cd.cd_gender,
        cd.cd_marital_status,
        hd.hd_income_band_sk,
        ca.ca_city,
        ca.ca_state,
        COUNT(DISTINCT wp.wp_web_page_sk) AS web_page_count
    FROM web_page wp
    JOIN date_dim d_wp
        ON wp.wp_creation_date_sk = d_wp.d_date_sk
    JOIN customer c
        ON wp.wp_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd
        ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
        ON c.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca
        ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE d_wp.d_year = 2022
    GROUP BY cd.cd_gender, cd.cd_marital_status, hd.hd_income_band_sk, ca.ca_city, ca.ca_state
)
SELECT
    s.cd_gender,
    s.cd_marital_status,
    s.hd_income_band_sk,
    s.ca_city,
    s.ca_state,
    s.total_net_paid,
    s.total_net_profit,
    s.order_count,
    COALESCE(w.web_page_count, 0) AS web_page_count
FROM sales_agg s
LEFT JOIN web_page_agg w
    ON s.cd_gender = w.cd_gender
    AND s.cd_marital_status = w.cd_marital_status
    AND s.hd_income_band_sk = w.hd_income_band_sk
    AND s.ca_city = w.ca_city
    AND s.ca_state = w.ca_state
ORDER BY s.total_net_profit DESC
LIMIT 20
