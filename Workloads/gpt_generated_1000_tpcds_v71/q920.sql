WITH reason_return_agg AS (
    SELECT
        r.r_reason_desc,
        cd.cd_credit_rating,
        cd.cd_gender,
        SUM(wr.wr_return_amt) AS total_return_amt,
        AVG(wr.wr_reversed_charge) AS avg_rev_charge,
        COUNT(DISTINCT wr.wr_order_number) AS distinct_orders,
        SUM(wr.wr_return_quantity) AS total_qty,
        CASE
            WHEN SUM(wr.wr_return_amt) > 1000 THEN 'HIGH'
            ELSE 'LOW'
        END AS return_level
    FROM web_returns wr
    JOIN customer_demographics cd
        ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN reason r
        ON wr.wr_reason_sk = r.r_reason_sk
    WHERE 
        cd.cd_credit_rating = 'Good'                     -- filter 1
        AND cd.cd_dep_employed_count >= 2                -- filter 2
        AND wr.wr_reversed_charge > 50                  -- filter 3
        AND r.r_reason_id = 'AAAAAAAAPAAAAAAA'          -- filter 4
        AND wr.wr_return_quantity >= 1                  -- filter 5
        AND EXISTS (
            SELECT 1
            FROM customer_demographics cd_ret
            WHERE cd_ret.cd_demo_sk = wr.wr_returning_cdemo_sk
              AND cd_ret.cd_credit_rating = 'Low Risk'
        )                                              -- semi‑join on returning demographics
        AND EXISTS (
            SELECT 1
            FROM reason r2
            WHERE r2.r_reason_sk = wr.wr_reason_sk
              AND r2.r_reason_desc LIKE '%product%'
        )                                              -- additional semi‑join filter
    GROUP BY r.r_reason_desc, cd.cd_credit_rating, cd.cd_gender
)
SELECT
    rra.r_reason_desc,
    rra.cd_credit_rating,
    rra.cd_gender,
    rra.total_return_amt,
    rra.avg_rev_charge,
    rra.distinct_orders,
    rra.return_level,
    ROW_NUMBER() OVER (PARTITION BY rra.r_reason_desc ORDER BY rra.total_return_amt DESC) AS reason_rank
FROM reason_return_agg rra
ORDER BY rra.total_return_amt DESC
LIMIT 100
