SELECT 
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    s.s_state,
    d.d_year,
    r.r_reason_desc,
    sm.sm_type,
    COUNT(*) AS total_returns,
    SUM(cr.cr_return_quantity) AS total_quantity,
    SUM(cr.cr_net_loss) AS total_net_loss,
    AVG(cr.cr_return_amount) AS avg_return_amount,
    SUM(cr.cr_fee) AS total_fees,
    SUM(cr.cr_return_ship_cost) AS total_shipping_cost,
    SUM(cr.cr_store_credit) AS total_store_credit,
    CASE 
        WHEN SUM(cr.cr_return_quantity) > 10 THEN 'HIGH_VOLUME' 
        ELSE 'LOW_VOLUME' 
    END AS volume_category,
    GROUPING(s.s_store_id)   AS grp_store,
    GROUPING(r.r_reason_desc) AS grp_reason,
    GROUPING(sm.sm_type)     AS grp_ship_mode,
    GROUPING(d.d_year)       AS grp_year
FROM catalog_returns cr
JOIN date_dim d 
    ON cr.cr_returned_date_sk = d.d_date_sk
JOIN reason r 
    ON cr.cr_reason_sk = r.r_reason_sk
JOIN ship_mode sm 
    ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN store s 
    ON s.s_closed_date_sk = d.d_date_sk
WHERE d.d_year BETWEEN 2015 AND 2020
  AND sm.sm_type IN ('Air', 'Ground')
GROUP BY ROLLUP (
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    s.s_state,
    d.d_year,
    r.r_reason_desc,
    sm.sm_type
)
HAVING COUNT(*) >= 5
ORDER BY total_net_loss DESC
LIMIT 100
