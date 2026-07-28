WITH sales_data AS (
    SELECT
        c.c_customer_sk,
        ca.ca_state,
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        cs.cs_net_paid AS net_amount,
        cs.cs_ext_tax AS tax_amount,
        cs.cs_ship_mode_sk,
        cs.cs_sold_date_sk AS sold_date_sk,
        'catalog' AS source
    FROM catalog_sales cs
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE sm.sm_code = 'AIR'
      AND ib.ib_lower_bound >= 50000
      AND cs.cs_sold_date_sk BETWEEN 2451545 AND 2451910
      AND ca.ca_county = 'Richland County'
      AND cs.cs_ext_tax > 0
),
returns_data AS (
    SELECT
        c.c_customer_sk,
        ca.ca_state,
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        sr.sr_net_loss AS net_amount,
        sr.sr_return_tax AS tax_amount,
        NULL AS cs_ship_mode_sk,
        sr.sr_returned_date_sk AS sold_date_sk,
        'return' AS source
    FROM store_returns sr
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE sr.sr_return_amt > 100
      AND ib.ib_upper_bound <= 150000
      AND sr.sr_returned_date_sk BETWEEN 2451545 AND 2451910
      AND ca.ca_state = 'CA'
      AND sr.sr_return_tax > 0
),
combined AS (
    SELECT * FROM sales_data
    UNION ALL
    SELECT * FROM returns_data
)
SELECT
    c.c_customer_id,
    comb.ca_state,
    SUM(comb.net_amount) AS total_net_amount,
    SUM(comb.tax_amount) AS total_tax_amount,
    COUNT(*) AS transaction_count,
    RANK() OVER (PARTITION BY comb.ca_state ORDER BY SUM(comb.net_amount) DESC) AS state_rank,
    DENSE_RANK() OVER (ORDER BY SUM(comb.net_amount) DESC) AS overall_rank,
    CASE
        WHEN SUM(comb.net_amount) > 0 THEN 'PROFIT'
        WHEN SUM(comb.net_amount) < 0 THEN 'LOSS'
        ELSE 'NEUTRAL'
    END AS profit_status
FROM combined comb
JOIN customer c ON comb.c_customer_sk = c.c_customer_sk
GROUP BY c.c_customer_id, comb.ca_state
ORDER BY overall_rank, total_net_amount DESC
LIMIT 100
