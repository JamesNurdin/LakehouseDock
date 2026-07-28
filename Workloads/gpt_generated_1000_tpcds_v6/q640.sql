/*
  Goal: Analyze the combined impact of catalog returns and web sales by year, month, call center, ship mode and return reason, while applying several filters on date, call center, ship mode contract, household vehicle count and web sales net paid. The query first builds a detailed base view joining all nine tables, then aggregates using GROUPING SETS to produce subtotals at various hierarchy levels, and finally adds a windowed average of return amounts per year.
*/
WITH base AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        cc.cc_name,
        cc.cc_call_center_id,
        sm.sm_ship_mode_id,
        sm.sm_contract,
        r.r_reason_desc,
        hd.hd_vehicle_count,
        cr.cr_return_amount,
        ws.ws_net_paid
    FROM catalog_returns cr
    JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    LEFT JOIN call_center cc
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
    LEFT JOIN ship_mode sm
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    LEFT JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    LEFT JOIN household_demographics hd
        ON cr.cr_returning_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN web_sales ws
        ON ws.ws_sold_date_sk = d.d_date_sk
    LEFT JOIN store s
        ON s.s_closed_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND d.d_month_seq BETWEEN 1 AND 12
      AND cc.cc_call_center_id = 'CC_001'
      AND sm.sm_contract = 'GNJr3g5i7oorKqtX'
      AND hd.hd_vehicle_count >= 1
      AND ws.ws_net_paid > 0
),
agg AS (
    SELECT
        d_year,
        d_month_seq,
        cc_name,
        sm_ship_mode_id,
        r_reason_desc,
        SUM(cr_return_amount) AS total_return_amount,
        SUM(ws_net_paid) AS total_net_paid
    FROM base
    GROUP BY GROUPING SETS (
        (d_year, d_month_seq, cc_name, sm_ship_mode_id, r_reason_desc),
        (d_year, d_month_seq, cc_name, sm_ship_mode_id),
        (d_year, d_month_seq, cc_name),
        (d_year, d_month_seq),
        (d_year)
    )
)
SELECT
    d_year,
    d_month_seq,
    cc_name,
    sm_ship_mode_id,
    r_reason_desc,
    total_return_amount,
    total_net_paid,
    AVG(total_return_amount) OVER (PARTITION BY d_year) AS avg_return_amount_per_year
FROM agg
WHERE total_return_amount > 0
  AND total_net_paid IS NOT NULL
  AND (cc_name IS NOT NULL OR sm_ship_mode_id IS NOT NULL)
  AND (r_reason_desc IS NOT NULL OR d_month_seq IS NOT NULL)
ORDER BY d_year, d_month_seq
LIMIT 100
