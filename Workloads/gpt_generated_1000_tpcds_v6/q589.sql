WITH returns_with_discount AS (
    SELECT
        ca.ca_state,
        d.d_year,
        'WithDiscount' AS promo_flag,
        sr.sr_return_amt,
        sr.sr_return_quantity,
        hd.hd_buy_potential,
        CASE WHEN sr.sr_return_amt > 500 THEN 'High' ELSE 'Low' END AS amt_category
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    JOIN catalog_page cp ON cp.cp_start_date_sk = d.d_date_sk
    JOIN promotion p ON p.p_start_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND hd.hd_buy_potential = '>10000'
      AND ca.ca_state = 'CA'
      AND p.p_discount_active = 'Y'
),
returns_without_discount AS (
    SELECT
        ca.ca_state,
        d.d_year,
        'NoDiscount' AS promo_flag,
        sr.sr_return_amt,
        sr.sr_return_quantity,
        hd.hd_buy_potential,
        CASE WHEN sr.sr_return_amt > 500 THEN 'High' ELSE 'Low' END AS amt_category
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    JOIN catalog_page cp ON cp.cp_start_date_sk = d.d_date_sk
    JOIN promotion p ON p.p_start_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND hd.hd_buy_potential = '>10000'
      AND ca.ca_state = 'CA'
      AND p.p_discount_active = 'N'
)
SELECT
    u.promo_flag,
    u.ca_state,
    u.d_year,
    u.amt_category,
    COUNT(*) AS cnt_returns,
    SUM(u.sr_return_quantity) AS total_qty,
    SUM(u.sr_return_amt) AS total_return_amt,
    AVG(u.sr_return_amt) AS avg_return_amt,
    MIN(u.sr_return_amt) AS min_return_amt,
    MAX(u.sr_return_amt) AS max_return_amt
FROM (
    SELECT * FROM returns_with_discount
    UNION ALL
    SELECT * FROM returns_without_discount
) u
GROUP BY GROUPING SETS (
    (promo_flag, ca_state, d_year, amt_category),
    (promo_flag, ca_state, d_year),
    (promo_flag, ca_state),
    (promo_flag),
    ()
)
ORDER BY promo_flag, ca_state, d_year, amt_category
