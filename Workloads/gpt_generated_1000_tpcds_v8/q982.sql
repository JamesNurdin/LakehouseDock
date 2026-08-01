WITH sales_sample AS (
    SELECT *
    FROM catalog_sales
    TABLESAMPLE BERNOULLI (10)   -- sample ~10% of rows for performance
),
agg AS (
    SELECT
        cc.cc_call_center_id,
        cc.cc_call_center_sk,
        sm.sm_ship_mode_id,
        sm.sm_ship_mode_sk,
        SUM(cs.cs_net_profit)               AS total_profit,
        COUNT(*)                           AS sales_cnt,
        AVG(cs.cs_ext_tax)                 AS avg_tax,
        SUM(cs.cs_quantity)                AS total_quantity
    FROM sales_sample cs
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE cs.cs_ship_date_sk BETWEEN 2450800 AND 2450900          -- 4th predicate
      AND cs.cs_ext_tax > 50                                      -- 5th predicate
      AND cc.cc_state = 'CA'                                      -- 6th predicate
      AND sm.sm_type = 'EXPRESS'                                  -- 7th predicate
    GROUP BY
        cc.cc_call_center_id,
        cc.cc_call_center_sk,
        sm.sm_ship_mode_id,
        sm.sm_ship_mode_sk
),
returns_agg AS (
    SELECT
        cr.cr_call_center_sk,
        cr.cr_ship_mode_sk,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_net_loss)      AS total_net_loss
    FROM catalog_returns cr
    GROUP BY cr.cr_call_center_sk, cr.cr_ship_mode_sk
),
combined AS (
    SELECT
        a.cc_call_center_id,
        a.cc_call_center_sk,
        a.sm_ship_mode_id,
        a.sm_ship_mode_sk,
        a.total_profit,
        r.total_return_amount,
        r.total_net_loss,
        (a.total_profit - COALESCE(r.total_return_amount, 0)) AS net_gain
    FROM agg a
    LEFT JOIN returns_agg r
        ON a.cc_call_center_sk = r.cr_call_center_sk
       AND a.sm_ship_mode_sk   = r.cr_ship_mode_sk
)
SELECT
    c.cc_call_center_id,
    c.sm_ship_mode_id,
    c.total_profit,
    c.total_return_amount,
    c.net_gain,
    -- correlated scalar subquery counting returns for a specific reason description
    (
        SELECT COUNT(*)
        FROM catalog_returns cr
        WHERE cr.cr_call_center_sk = c.cc_call_center_sk
          AND cr.cr_reason_sk = (
                SELECT r.r_reason_sk
                FROM reason r
                WHERE r.r_reason_desc LIKE '%size%'
                LIMIT 1
          )
    ) AS size_reason_return_cnt,
    lt.qty_per_center,
    mult.multiplier
FROM combined c
JOIN call_center cc
    ON c.cc_call_center_id = cc.cc_call_center_id
JOIN ship_mode sm
    ON c.sm_ship_mode_id = sm.sm_ship_mode_id
-- LATERAL subquery that computes total quantity sold by the same call center
CROSS JOIN LATERAL (
    SELECT SUM(cs.cs_quantity) AS qty_per_center
    FROM catalog_sales cs
    WHERE cs.cs_call_center_sk = c.cc_call_center_sk
) lt
-- Cartesian product between a small dimension (reason limited to 3 rows) and a computed set of multipliers
CROSS JOIN (
    SELECT r.r_reason_id
    FROM reason r
    WHERE r.r_reason_sk IN (5,6,7)   -- small slice of the reason dimension
) reason_dim
CROSS JOIN (VALUES (1), (2), (3)) AS mult(multiplier)
WHERE c.net_gain > 0                                 -- 8th predicate
  AND c.total_profit > 1000                          -- 9th predicate
  AND c.total_return_amount IS NOT NULL             -- 10th predicate
  AND sm.sm_code = 'AIR'                             -- 11th predicate
ORDER BY c.net_gain DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
