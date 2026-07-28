WITH agg_returns AS (
    SELECT
        w.w_warehouse_id,
        w.w_warehouse_name,
        sm.sm_type,
        d.d_year,
        d.d_month_seq,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_return_tax) AS total_return_tax,
        COUNT(*) AS return_cnt
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    WHERE d.d_year = 2001                                 -- filter 1: specific year
      AND cc.cc_state = 'CA'                              -- filter 2: state of call center
      AND sm.sm_contract LIKE 'Yv%'                       -- filter 3: contract pattern
      AND w.w_county = 'Bronx County'                     -- filter 4: warehouse county
      AND cr.cr_return_amount > 500.00                    -- filter 5: high return amount
      AND cr.cr_return_quantity BETWEEN 1 AND 5           -- filter 6: quantity range
      AND cr.cr_return_tax < 100.00                       -- filter 7: tax ceiling
    GROUP BY
        w.w_warehouse_id,
        w.w_warehouse_name,
        sm.sm_type,
        d.d_year,
        d.d_month_seq
)
SELECT
    w_warehouse_id,
    w_warehouse_name,
    sm_type,
    d_year,
    d_month_seq,
    total_return_amount,
    total_return_tax,
    return_cnt,
    RANK() OVER (PARTITION BY d_year ORDER BY total_return_amount DESC) AS warehouse_rank,
    ROW_NUMBER() OVER (ORDER BY total_return_amount DESC) AS overall_seq
FROM agg_returns
ORDER BY total_return_amount DESC
LIMIT 100
