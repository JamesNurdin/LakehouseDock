WITH ss AS (
    SELECT
        ss_sold_date_sk,
        ss_customer_sk,
        ss_hdemo_sk,
        ss_addr_sk,
        ss_quantity,
        ss_sales_price,
        ss_net_paid
    FROM store_sales
    WHERE ss_quantity > 2
      AND ss_sales_price > 100
),
wd AS (
    SELECT
        ws_bill_hdemo_sk,
        ws_bill_addr_sk,
        ws_bill_customer_sk,
        ws_quantity,
        ws_sales_price,
        ws_net_paid
    FROM web_sales
    WHERE ws_quantity > 1
      AND ws_sales_price > 150
)
SELECT
    ca.ca_state,
    ca.ca_county,
    ca.ca_street_type,
    hd.hd_buy_potential,
    ib.ib_lower_bound,
    COUNT(DISTINCT ss.ss_customer_sk) AS distinct_store_customers,
    COUNT(DISTINCT wd.ws_bill_customer_sk) AS distinct_web_customers,
    SUM(ss.ss_net_paid) AS total_store_net_paid,
    SUM(wd.ws_net_paid) AS total_web_net_paid,
    AVG(ss.ss_quantity) AS avg_store_quantity,
    MAX(wd.ws_sales_price) AS max_web_sales_price
FROM ss
JOIN household_demographics hd
    ON ss.ss_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN customer_address ca
    ON ss.ss_addr_sk = ca.ca_address_sk
JOIN wd
    ON wd.ws_bill_hdemo_sk = hd.hd_demo_sk
WHERE ca.ca_state = 'TX'
  AND ca.ca_county = 'Washington County'
  AND ca.ca_street_type = 'Ave'
  AND hd.hd_buy_potential = '>10000'
  AND ib.ib_lower_bound >= 50000
GROUP BY
    ca.ca_state,
    ca.ca_county,
    ca.ca_street_type,
    hd.hd_buy_potential,
    ib.ib_lower_bound
ORDER BY total_store_net_paid DESC
LIMIT 100
