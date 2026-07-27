WITH catalog_agg AS (
    SELECT
        'Catalog' AS src,
        sm.sm_type AS category,
        td.t_hour AS hour_of_day,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_return_quantity) AS total_qty
    FROM catalog_returns cr
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN time_dim td ON cr.cr_returned_time_sk = td.t_time_sk
    WHERE td.t_hour BETWEEN 9 AND 11
    GROUP BY sm.sm_type, td.t_hour
),
store_agg AS (
    SELECT
        'Store' AS src,
        ca.ca_state AS category,
        td.t_hour AS hour_of_day,
        SUM(sr.sr_return_amt) AS total_return_amount,
        SUM(sr.sr_return_quantity) AS total_qty
    FROM store_returns sr
    JOIN time_dim td ON sr.sr_return_time_sk = td.t_time_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    WHERE ca.ca_country = 'United States'
      AND td.t_hour BETWEEN 9 AND 17
    GROUP BY ca.ca_state, td.t_hour
)
SELECT src, category, hour_of_day, total_return_amount, total_qty
FROM catalog_agg
UNION ALL
SELECT src, category, hour_of_day, total_return_amount, total_qty
FROM store_agg
ORDER BY src, total_return_amount DESC, hour_of_day
LIMIT 100
