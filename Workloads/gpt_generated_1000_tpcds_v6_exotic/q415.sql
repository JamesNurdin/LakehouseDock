WITH center_returns AS (
    SELECT
        cc.cc_call_center_sk,
        cc.cc_name,
        cc.cc_division,
        cc.cc_division_name,
        cc.cc_county,
        cc.cc_manager,
        COUNT(cr.cr_order_number) AS return_cnt,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_store_credit) AS total_store_credit,
        CASE 
            WHEN SUM(cr.cr_return_amount) > 1000 THEN 'High'
            WHEN SUM(cr.cr_return_amount) > 500  THEN 'Medium'
            ELSE 'Low'
        END AS return_level
    FROM tpcds.call_center cc
    LEFT JOIN tpcds.catalog_returns cr
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
    WHERE
        cc.cc_county IN ('Bronx County', 'Dauphin County')
        AND cc.cc_manager = 'Felipe Perkins'
        AND cc.cc_gmt_offset BETWEEN -5.00 AND 5.00
        AND cc.cc_rec_start_date >= DATE '2001-01-01'
        AND cc.cc_rec_end_date <= DATE '2005-12-31'
        AND (cr.cr_returned_time_sk IS NULL OR cr.cr_returned_time_sk IN (53881, 64669))
        AND cc.cc_state = 'CA'
    GROUP BY
        cc.cc_call_center_sk,
        cc.cc_name,
        cc.cc_division,
        cc.cc_division_name,
        cc.cc_county,
        cc.cc_manager
),
aggregated_division AS (
    SELECT
        cr.cc_division AS division,
        cr.cc_division_name AS division_name,
        AVG(cr.total_return_amount) AS avg_return_amount,
        SUM(cr.return_cnt) AS total_returns,
        MAX(CASE WHEN cr.return_level = 'High' THEN 1 ELSE 0 END) AS has_high
    FROM center_returns cr
    GROUP BY cr.cc_division, cr.cc_division_name
)
SELECT
    division,
    division_name,
    avg_return_amount,
    total_returns,
    has_high,
    ROW_NUMBER() OVER (PARTITION BY division ORDER BY avg_return_amount DESC) AS rank_by_avg
FROM aggregated_division
WHERE avg_return_amount > 100
  AND total_returns >= 5
  AND has_high = 1
  AND division_name LIKE '%Division%'
  AND avg_return_amount IS NOT NULL
ORDER BY avg_return_amount DESC
LIMIT 100
