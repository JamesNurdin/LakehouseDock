WITH base AS (
    SELECT
        cc.cc_call_center_id,
        cc.cc_company_name,
        d.d_year,
        ca.ca_state,
        ca.ca_location_type,
        ws.ws_ext_sales_price,
        ws.ws_ext_discount_amt,
        ws.ws_net_profit,
        sr.sr_return_amt,
        CASE WHEN ws.ws_ext_discount_amt > 5000 THEN 'HIGH_DISCOUNT' ELSE 'LOW_DISCOUNT' END AS discount_category
    FROM call_center AS cc
    JOIN date_dim AS d
        ON cc.cc_open_date_sk = d.d_date_sk
    JOIN web_sales AS ws
        ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN customer_address AS ca
        ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN store_returns AS sr
        ON sr.sr_addr_sk = ca.ca_address_sk
        AND sr.sr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2000
      AND ca.ca_state = 'CA'
      AND ca.ca_location_type = 'apartment'
      AND ws.ws_ext_discount_amt > 1000
      AND cc.cc_company_name IS NOT NULL
)
SELECT
    discount_category,
    d_year,
    ca_state,
    SUM(ws_ext_sales_price) AS total_sales,
    SUM(sr_return_amt) AS total_returns,
    AVG(ws_net_profit) AS avg_profit,
    SUM(ws_ext_discount_amt) AS total_discount
FROM base
GROUP BY GROUPING SETS (
    (discount_category, d_year, ca_state),
    (discount_category, d_year),
    (discount_category),
    ()
)
ORDER BY total_sales DESC
LIMIT 100
