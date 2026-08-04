/*
  Goal: Identify household demographic groups (by income band) that experienced net loss from catalog returns, ranking them across income bands and overall, while demonstrating advanced SQL features such as scalar subquery comparison, anti‑semi‑join, INTERSECT, UNION, window functions and pagination.
*/
WITH refunded AS (
    SELECT
        cr_refunded_hdemo_sk AS hd_demo_sk,
        SUM(cr_return_amount)      AS total_refund_amount,
        SUM(cr_net_loss)           AS total_net_loss
    FROM catalog_returns
    WHERE cr_return_amount > (
        SELECT MAX(ib_upper_bound)
        FROM income_band
        WHERE ib_income_band_sk = 14
    )
    GROUP BY cr_refunded_hdemo_sk
),
returning AS (
    SELECT
        cr_returning_hdemo_sk AS hd_demo_sk,
        SUM(cr_return_quantity) AS total_return_qty,
        SUM(cr_return_ship_cost) AS total_ship_cost
    FROM catalog_returns
    WHERE cr_return_quantity > 1
    GROUP BY cr_returning_hdemo_sk
),
demo_income AS (
    SELECT
        hd.hd_demo_sk,
        hd.hd_dep_count,
        hd.hd_vehicle_count,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM household_demographics hd
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE ib.ib_lower_bound >= 50000                -- predicate 1
      AND ib.ib_upper_bound <= 200000               -- predicate 2
      AND hd.hd_dep_count IN (1, 2, 3)               -- predicate 3
      AND hd.hd_vehicle_count <> 0                  -- predicate 4
),
combined AS (
    SELECT
        d.hd_demo_sk,
        d.hd_dep_count,
        d.hd_vehicle_count,
        d.ib_lower_bound,
        d.ib_upper_bound,
        COALESCE(r.total_return_qty, 0)   AS total_return_qty,
        COALESCE(f.total_refund_amount, 0) AS total_refund_amount,
        COALESCE(r.total_ship_cost, 0)    AS total_ship_cost,
        COALESCE(f.total_net_loss, 0)     AS total_net_loss
    FROM demo_income d
    LEFT JOIN returning r ON d.hd_demo_sk = r.hd_demo_sk
    LEFT JOIN refunded  f ON d.hd_demo_sk = f.hd_demo_sk
    WHERE d.hd_demo_sk NOT IN (
        SELECT hd_demo_sk
        FROM household_demographics
        WHERE hd_vehicle_count = 0
    )                                            -- anti‑semi‑join predicate
      AND d.hd_demo_sk IN (
          SELECT hd_demo_sk FROM household_demographics WHERE hd_dep_count >= 2
          INTERSECT
          SELECT hd_demo_sk FROM household_demographics WHERE hd_dep_count <= 3
      )                                            -- INTERSECT predicate
),
union_set AS (
    SELECT
        hd_demo_sk,
        ib_lower_bound,
        ib_upper_bound,
        total_return_qty,
        total_refund_amount,
        total_net_loss,
        ROW_NUMBER() OVER (PARTITION BY ib_lower_bound ORDER BY total_net_loss DESC) AS rn_within_income,
        RANK()       OVER (ORDER BY total_net_loss DESC)                     AS overall_rank,
        CASE WHEN total_return_qty = 0 THEN 'No Returns' ELSE 'Has Returns' END AS return_flag
    FROM combined
    WHERE total_net_loss > 0                                               -- predicate 5
    UNION
    SELECT
        hd_demo_sk,
        ib_lower_bound,
        ib_upper_bound,
        total_return_qty,
        total_refund_amount,
        total_net_loss,
        NULL AS rn_within_income,
        NULL AS overall_rank,
        NULL AS return_flag
    FROM combined
    WHERE total_net_loss IS NULL                                           -- predicate 6
)
SELECT *
FROM union_set
ORDER BY overall_rank
OFFSET 0
LIMIT 100
