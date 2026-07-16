SELECT
    s.s_store_id,
    d.d_year,
    CASE
        WHEN sm.sm_type = 'AIR' THEN 'AIR'
        WHEN sm.sm_type = 'GROUND' THEN 'GROUND'
        ELSE 'OTHER'
    END AS shipping_category,
    CASE
        WHEN cr.cr_return_quantity > 1 THEN 'MULTI_ITEM'
        ELSE 'SINGLE_ITEM'
    END AS return_type,
    ca_ret.ca_city AS returning_city,
    COUNT(*) AS total_returns,
    SUM(cr.cr_net_loss) AS total_net_loss,
    SUM(cr.cr_return_amount) AS total_return_amount,
    AVG(cr.cr_return_quantity) AS avg_return_quantity,
    SUM(CASE WHEN cr.cr_return_amount > 100 THEN cr.cr_return_amount ELSE 0 END) AS high_value_return_amount,
    COUNT(DISTINCT ca_ref.ca_state) AS distinct_refunded_states
FROM catalog_returns cr
JOIN date_dim d
    ON cr.cr_returned_date_sk = d.d_date_sk
JOIN customer_address ca_ref
    ON cr.cr_refunded_addr_sk = ca_ref.ca_address_sk
JOIN customer_address ca_ret
    ON cr.cr_returning_addr_sk = ca_ret.ca_address_sk
JOIN ship_mode sm
    ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
GROUP BY
    s.s_store_id,
    d.d_year,
    CASE
        WHEN sm.sm_type = 'AIR' THEN 'AIR'
        WHEN sm.sm_type = 'GROUND' THEN 'GROUND'
        ELSE 'OTHER'
    END,
    CASE
        WHEN cr.cr_return_quantity > 1 THEN 'MULTI_ITEM'
        ELSE 'SINGLE_ITEM'
    END,
    ca_ret.ca_city
HAVING COUNT(*) > 5
ORDER BY total_net_loss DESC
LIMIT 50
