WITH web_part AS (
    SELECT
        'web' AS source,
        ws.ws_bill_customer_sk AS customer_sk,
        ca.ca_address_sk AS address_sk,
        ca.ca_city AS city,
        CONCAT(CAST(ib.ib_lower_bound AS varchar), '-', CAST(ib.ib_upper_bound AS varchar)) AS income_band_range,
        ws.ws_net_paid_inc_ship_tax AS amount,
        ws.ws_sold_date_sk AS date_sk
    FROM tpcds.web_sales ws
    JOIN tpcds.customer_address ca
      ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN tpcds.household_demographics hd
      ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN tpcds.income_band ib
      ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN tpcds.web_site wsit
      ON ws.ws_web_site_sk = wsit.web_site_sk
    WHERE ws.ws_net_paid_inc_ship_tax > 2000
      AND wsit.web_suite_number LIKE 'Suite 2%'
),
store_part AS (
    SELECT
        'store' AS source,
        sr.sr_customer_sk AS customer_sk,
        ca.ca_address_sk AS address_sk,
        ca.ca_city AS city,
        CONCAT(CAST(ib.ib_lower_bound AS varchar), '-', CAST(ib.ib_upper_bound AS varchar)) AS income_band_range,
        sr.sr_return_amt AS amount,
        sr.sr_returned_date_sk AS date_sk
    FROM tpcds.store_returns sr
    JOIN tpcds.customer_address ca
      ON sr.sr_addr_sk = ca.ca_address_sk
    JOIN tpcds.household_demographics hd
      ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN tpcds.income_band ib
      ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE sr.sr_return_amt > 500
      AND ca.ca_state = 'CA'
),
combined AS (
    SELECT * FROM web_part
    UNION ALL
    SELECT * FROM store_part
)
SELECT
    source,
    customer_sk,
    address_sk,
    city,
    income_band_range,
    amount,
    date_sk
FROM combined c
WHERE NOT EXISTS (
    SELECT 1
    FROM tpcds.store_returns sr2
    WHERE sr2.sr_addr_sk = c.address_sk
      AND sr2.sr_return_amt > 1000
)
ORDER BY amount DESC
LIMIT 100
