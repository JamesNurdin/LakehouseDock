WITH address_arrays AS (
    SELECT
        ca_address_sk,
        ARRAY[ca_city, ca_state] AS city_state_arr
    FROM customer_address
)
SELECT
    d.d_year,
    hd.hd_buy_potential,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    AVG(ss.ss_coupon_amt) AS avg_coupon_amount,
    COUNT(DISTINCT ss.ss_ticket_number) AS distinct_tickets,
    MIN(cr.cr_return_amount) AS min_return_amount,
    MAX(wr.wr_return_amt) AS max_web_return_amount,
    CASE
        WHEN r.r_reason_desc LIKE '%damaged%' THEN 'Damaged'
        WHEN r.r_reason_desc LIKE '%not wanted%' THEN 'Not Wanted'
        ELSE 'Other'
    END AS return_category,
    city_state.city_state_val AS city_state_value
FROM store_sales ss
JOIN date_dim d
    ON ss.ss_sold_date_sk = d.d_date_sk
JOIN household_demographics hd
    ON ss.ss_hdemo_sk = hd.hd_demo_sk
JOIN address_arrays ca
    ON ss.ss_addr_sk = ca.ca_address_sk
CROSS JOIN UNNEST(ca.city_state_arr) AS city_state (city_state_val)
JOIN catalog_returns cr
    ON cr.cr_returned_date_sk = d.d_date_sk
JOIN reason r
    ON cr.cr_reason_sk = r.r_reason_sk
JOIN web_returns wr
    ON wr.wr_returned_date_sk = d.d_date_sk
WHERE d.d_year = 2001
  AND d.d_month_seq BETWEEN 1200 AND 1211
  AND hd.hd_buy_potential = '1001-5000'
  AND hd.hd_vehicle_count >= 1
  AND ss.ss_store_sk IN (676, 925)
GROUP BY
    d.d_year,
    hd.hd_buy_potential,
    r.r_reason_desc,
    city_state.city_state_val
ORDER BY total_sales DESC
LIMIT 100
