WITH sales_with_site AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_net_paid_inc_tax,
        ss.ss_coupon_amt,
        ss.ss_quantity,
        d_sales.d_year,
        cd.cd_gender,
        cd.cd_marital_status,
        hd.hd_buy_potential,
        ca.ca_city,
        ws.web_market_manager,
        ws.web_company_name,
        CONCAT(ca.ca_city, ' - ', ws.web_company_name) AS city_company,
        regexp_extract(ws.web_name, '^([^ ]+)', 1) AS web_name_first_word
    FROM store_sales ss
    JOIN date_dim d_sales ON ss.ss_sold_date_sk = d_sales.d_date_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN web_site ws ON ws.web_open_date_sk = d_sales.d_date_sk
    WHERE regexp_like(ws.web_market_manager, '^G.*')
      AND ws.web_company_name LIKE '%a%'
)
SELECT
    s.web_market_manager,
    s.web_company_name,
    s.city_company,
    s.web_name_first_word,
    s.d_year,
    s.cd_gender,
    s.cd_marital_status,
    s.hd_buy_potential,
    COUNT(*) AS transaction_count,
    SUM(s.ss_net_paid_inc_tax) AS total_net_paid_inc_tax,
    AVG(s.ss_coupon_amt) AS avg_coupon_amount
FROM sales_with_site s
GROUP BY
    s.web_market_manager,
    s.web_company_name,
    s.city_company,
    s.web_name_first_word,
    s.d_year,
    s.cd_gender,
    s.cd_marital_status,
    s.hd_buy_potential
ORDER BY total_net_paid_inc_tax DESC
LIMIT 100
