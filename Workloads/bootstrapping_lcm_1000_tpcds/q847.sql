WITH store_yearly_totals AS (
    SELECT
        s.s_store_id,
        d.d_year,
        SUM(cr.cr_return_amount) AS yearly_return_amount
    FROM catalog_returns cr
    JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN store s
        ON s.s_closed_date_sk = d.d_date_sk
    GROUP BY s.s_store_id, d.d_year
)
SELECT
    s.s_store_id,
    s.s_state,
    d.d_year,
    d.d_month_seq,
    sm.sm_type,
    COUNT(DISTINCT cr.cr_order_number) AS num_returns,
    SUM(cr.cr_return_amount) AS monthly_return_amount,
    AVG(cr.cr_return_tax) AS avg_return_tax,
    SUM(cr.cr_fee) AS total_fee,
    COUNT(DISTINCT ra.ca_address_id) AS num_refunded_addresses,
    COUNT(DISTINCT rca.ca_address_id) AS num_returning_addresses,
    SY.yearly_return_amount,
    (SUM(cr.cr_return_amount) / SY.yearly_return_amount) AS monthly_to_yearly_ratio
FROM catalog_returns cr
JOIN date_dim d
    ON cr.cr_returned_date_sk = d.d_date_sk
JOIN ship_mode sm
    ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
JOIN customer_address ra
    ON cr.cr_refunded_addr_sk = ra.ca_address_sk
JOIN customer_address rca
    ON cr.cr_returning_addr_sk = rca.ca_address_sk
JOIN store_yearly_totals SY
    ON SY.s_store_id = s.s_store_id
    AND SY.d_year = d.d_year
WHERE d.d_year BETWEEN 2015 AND 2020
  AND sm.sm_type = 'AIR'
GROUP BY
    s.s_store_id,
    s.s_state,
    d.d_year,
    d.d_month_seq,
    sm.sm_type,
    SY.yearly_return_amount
HAVING SUM(cr.cr_return_amount) > 1000
ORDER BY monthly_to_yearly_ratio DESC
LIMIT 100
