/*
Goal: Analyze store return performance by return reason and fiscal year, summarizing counts, total return amount, average quantity, and loss metrics. The query ranks reasons within each year and calculates a cumulative return amount per year.
*/
WITH base AS (
    SELECT
        sr.sr_returned_date_sk,
        sr.sr_reason_sk,
        sr.sr_customer_sk,
        sr.sr_return_quantity,
        sr.sr_return_amt,
        sr.sr_net_loss,
        d.d_year,
        d.d_dow,
        r.r_reason_desc
    FROM store_returns sr
    JOIN date_dim d
        ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN reason r
        ON sr.sr_reason_sk = r.r_reason_sk
    WHERE d.d_year BETWEEN 2000 AND 2002                     -- filter 1
      AND d.d_dow IN (2, 3, 4)                               -- filter 2
      AND r.r_reason_desc LIKE '%Did not like%'            -- filter 3
      AND sr.sr_customer_sk > 500000                        -- filter 4
),
agg AS (
    SELECT
        d_year,
        r_reason_desc,
        COUNT(*) AS returns_cnt,
        SUM(sr_return_amt) AS total_return_amount,
        AVG(sr_return_quantity) AS avg_quantity,
        SUM(CASE WHEN sr_net_loss > 0 THEN sr_net_loss ELSE 0 END) AS total_positive_loss,
        SUM(CASE WHEN sr_net_loss <= 0 THEN 1 ELSE 0 END) AS non_positive_loss_cnt
    FROM base
    GROUP BY d_year, r_reason_desc
)
SELECT
    d_year,
    r_reason_desc,
    returns_cnt,
    total_return_amount,
    avg_quantity,
    total_positive_loss,
    non_positive_loss_cnt,
    SUM(total_return_amount) OVER (
        PARTITION BY d_year
        ORDER BY total_return_amount DESC
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_return_by_year,
    RANK() OVER (
        PARTITION BY d_year
        ORDER BY total_return_amount DESC
    ) AS return_rank_by_year
FROM agg
ORDER BY total_return_amount DESC
LIMIT 100
