WITH
-- Base web_returns rows
base_wr AS (
    SELECT
        wr.wr_returned_date_sk,
        wr.wr_returned_time_sk,
        wr.wr_web_page_sk,
        wr.wr_reason_sk,
        wr.wr_return_amt,
        wr.wr_return_quantity,
        wr.wr_order_number
    FROM web_returns wr
),

-- Join to all dimension tables and apply filters, including a correlated EXISTS
filtered_wr AS (
    SELECT
        d_ret.d_year,
        cc.cc_call_center_id,
        bw.wr_return_amt,
        bw.wr_return_quantity
    FROM base_wr bw
    JOIN date_dim d_ret
        ON bw.wr_returned_date_sk = d_ret.d_date_sk
    JOIN time_dim t
        ON bw.wr_returned_time_sk = t.t_time_sk
    JOIN reason rs
        ON bw.wr_reason_sk = rs.r_reason_sk
    JOIN web_page wp
        ON bw.wr_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN call_center cc
        ON cc.cc_open_date_sk = d_ret.d_date_sk
    LEFT JOIN catalog_page cp
        ON cp.cp_start_date_sk = d_ret.d_date_sk
    LEFT JOIN web_site ws
        ON ws.web_open_date_sk = d_ret.d_date_sk
    WHERE d_ret.d_current_month = 'Y'
      AND d_ret.d_week_seq IN (8, 11, 17)
      AND t.t_hour BETWEEN 9 AND 17
      AND EXISTS (
            SELECT 1
            FROM web_page wp2
            WHERE wp2.wp_type = wp.wp_type
              AND wp2.wp_url IS NOT NULL
        )
),

-- First aggregation using GROUPING SETS and HAVING
agg1 AS (
    SELECT
        d_year,
        cc_call_center_id,
        SUM(wr_return_amt) AS total_return_amt,
        COUNT(*)          AS return_cnt,
        AVG(wr_return_quantity) AS avg_qty
    FROM filtered_wr
    GROUP BY GROUPING SETS (
        (d_year, cc_call_center_id),
        (d_year),
        (cc_call_center_id)
    )
    HAVING SUM(wr_return_amt) > 500
),

-- Second branch that uses a FULL OUTER JOIN between call_center and web_site
full_join AS (
    SELECT
        d_full.d_year,
        cc2.cc_call_center_id,
        ws2.web_site_id,
        wr.wr_return_amt,
        wr.wr_return_quantity
    FROM date_dim d_full
    FULL OUTER JOIN call_center cc2
        ON cc2.cc_closed_date_sk = d_full.d_date_sk
    FULL OUTER JOIN web_site ws2
        ON ws2.web_close_date_sk = d_full.d_date_sk
    LEFT JOIN web_returns wr
        ON wr.wr_returned_date_sk = d_full.d_date_sk
    WHERE d_full.d_current_month = 'Y'
      AND d_full.d_week_seq IN (8, 11, 17)
),

agg2 AS (
    SELECT
        d_year,
        cc_call_center_id,
        SUM(wr_return_amt) AS total_return_amt,
        COUNT(wr_return_amt) AS return_cnt,
        AVG(wr_return_quantity) AS avg_qty
    FROM full_join
    GROUP BY GROUPING SETS (
        (d_year, cc_call_center_id),
        (d_year),
        (cc_call_center_id)
    )
    HAVING SUM(wr_return_amt) > 500
),

-- Union of the two aggregated result sets (distinct by default)
union_set AS (
    SELECT d_year, cc_call_center_id, total_return_amt, return_cnt, avg_qty
    FROM agg1
    UNION DISTINCT
    SELECT d_year, cc_call_center_id, total_return_amt, return_cnt, avg_qty
    FROM agg2
),

-- Exclusion set: same shape but filtered to a specific reason (using the reason table via a re‑join)
exclude_set AS (
    SELECT
        d_ret.d_year,
        cc.cc_call_center_id,
        SUM(bw.wr_return_amt) AS total_return_amt,
        COUNT(*)          AS return_cnt,
        AVG(bw.wr_return_quantity) AS avg_qty
    FROM base_wr bw
    JOIN date_dim d_ret
        ON bw.wr_returned_date_sk = d_ret.d_date_sk
    JOIN reason rs
        ON bw.wr_reason_sk = rs.r_reason_sk
    LEFT JOIN call_center cc
        ON cc.cc_open_date_sk = d_ret.d_date_sk
    WHERE rs.r_reason_desc = 'Damaged Item'
    GROUP BY GROUPING SETS (
        (d_ret.d_year, cc.cc_call_center_id),
        (d_ret.d_year),
        (cc.cc_call_center_id)
    )
    HAVING SUM(bw.wr_return_amt) > 500
),

-- Apply EXCEPT to drop the excluded groups
final_set AS (
    SELECT * FROM union_set
    EXCEPT
    SELECT d_year, cc_call_center_id, total_return_amt, return_cnt, avg_qty FROM exclude_set
)

SELECT
    d_year,
    cc_call_center_id,
    total_return_amt,
    return_cnt,
    avg_qty,
    ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY total_return_amt DESC) AS rn
FROM final_set
ORDER BY total_return_amt DESC
LIMIT 100
