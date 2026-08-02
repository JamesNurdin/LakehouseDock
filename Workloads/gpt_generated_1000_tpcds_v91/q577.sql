/* Goal: Analyze return performance across catalog and web channels by year, state and ship mode, aggregating return amounts and net loss, applying extensive filters, excluding years with high‑quantity catalog returns, and adding window‑based rankings. */
WITH catalog_agg AS (
    SELECT
        d.d_year,
        w.w_state,
        sm.sm_type,
        ib.ib_upper_bound,
        SUM(cr.cr_return_amount)      AS total_return_amount,
        SUM(cr.cr_net_loss)           AS total_net_loss,
        COUNT(*)                      AS cnt_returns,
        SUM(cr.cr_return_quantity)    AS total_quantity
    FROM tpcds.catalog_returns cr
    JOIN tpcds.date_dim d
      ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN tpcds.household_demographics hd_ref
      ON cr.cr_refunded_hdemo_sk = hd_ref.hd_demo_sk
    JOIN tpcds.household_demographics hd_ret
      ON cr.cr_returning_hdemo_sk = hd_ret.hd_demo_sk
    JOIN tpcds.ship_mode sm
      ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN tpcds.warehouse w
      ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN tpcds.income_band ib
      ON hd_ref.hd_income_band_sk = ib.ib_income_band_sk
    WHERE cr.cr_reason_sk IN (30, 56, 62)                       -- predicate 1
      AND cr.cr_return_ship_cost > 100                         -- predicate 2
      AND d.d_current_month = 'Y'                              -- predicate 3
      AND hd_ref.hd_buy_potential = '>10000'                   -- predicate 4
      AND ib.ib_upper_bound >= 5000                            -- predicate 5
    GROUP BY ROLLUP (d.d_year, w.w_state, sm.sm_type, ib.ib_upper_bound)
),

web_agg AS (
    SELECT
        d.d_year,
        CAST(NULL AS VARCHAR)        AS w_state,
        CAST(NULL AS VARCHAR)        AS sm_type,
        ib.ib_upper_bound,
        SUM(wr.wr_return_amt)         AS total_return_amount,
        SUM(wr.wr_net_loss)           AS total_net_loss,
        COUNT(*)                      AS cnt_returns,
        SUM(wr.wr_return_quantity)    AS total_quantity
    FROM tpcds.web_returns wr
    JOIN tpcds.date_dim d
      ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN tpcds.household_demographics hd_ref
      ON wr.wr_refunded_hdemo_sk = hd_ref.hd_demo_sk
    JOIN tpcds.income_band ib
      ON hd_ref.hd_income_band_sk = ib.ib_income_band_sk
    WHERE wr.wr_reason_sk IN (30, 56, 62)                       -- predicate 1
      AND wr.wr_return_ship_cost > 100                         -- predicate 2
      AND d.d_current_month = 'Y'                              -- predicate 3
      AND hd_ref.hd_buy_potential = '>10000'                   -- predicate 4
      AND ib.ib_upper_bound >= 5000                            -- predicate 5
    GROUP BY ROLLUP (d.d_year, ib.ib_upper_bound)
),

union_agg AS (
    SELECT * FROM catalog_agg
    UNION
    SELECT * FROM web_agg
),

final_agg AS (
    SELECT
        d_year,
        w_state,
        sm_type,
        ib_upper_bound,
        SUM(total_return_amount) AS sum_return_amount,
        SUM(total_net_loss)      AS sum_net_loss,
        SUM(cnt_returns)         AS total_cnt,
        SUM(total_quantity)      AS sum_quantity
    FROM union_agg ua
    WHERE NOT EXISTS (
        SELECT 1
        FROM tpcds.catalog_returns cr2
        JOIN tpcds.date_dim d2
          ON cr2.cr_returned_date_sk = d2.d_date_sk
        WHERE d2.d_year = ua.d_year
          AND cr2.cr_return_quantity > 10
    )
    GROUP BY d_year, w_state, sm_type, ib_upper_bound
    HAVING SUM(total_return_amount) > 1000
)
SELECT
    d_year,
    w_state,
    sm_type,
    ib_upper_bound,
    sum_return_amount,
    sum_net_loss,
    total_cnt,
    sum_quantity,
    AVG(sum_return_amount) OVER (PARTITION BY d_year)               AS avg_return_amount_by_year,
    ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY sum_net_loss DESC) AS loss_rank_in_year
FROM final_agg
ORDER BY d_year DESC, sum_net_loss DESC
LIMIT 100
