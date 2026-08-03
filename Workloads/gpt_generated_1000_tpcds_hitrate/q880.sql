WITH sr_agg AS (
    SELECT
        sr_returned_date_sk,
        sr_return_time_sk,
        sr_reason_sk,
        COUNT(*) AS cnt_returns,
        SUM(sr_return_amt) AS total_return_amt,
        AVG(sr_return_tax) AS avg_return_tax
    FROM store_returns
    WHERE sr_return_quantity > 1
    GROUP BY sr_returned_date_sk, sr_return_time_sk, sr_reason_sk
),

base AS (
    SELECT
        r_store.r_reason_desc AS r_reason_desc,
        d_store.d_year AS d_year,
        dy.d_year AS extra_year,
        v.k AS value_k,
        d_store.d_weekend,
        t_store.t_hour,
        CASE WHEN d_store.d_weekend = 'Y' THEN 'Weekend' ELSE 'Weekday' END AS day_type,
        SUM(sra.cnt_returns) AS total_cnt,
        SUM(sra.total_return_amt) AS total_return_amt,
        AVG(sra.avg_return_tax) AS avg_return_tax
    FROM sr_agg sra
    JOIN date_dim d_store
        ON sra.sr_returned_date_sk = d_store.d_date_sk                                 -- join 1
    JOIN time_dim t_store
        ON sra.sr_return_time_sk = t_store.t_time_sk                                   -- join 2
    JOIN reason r_store
        ON sra.sr_reason_sk = r_store.r_reason_sk                                      -- join 3
    JOIN web_returns wr
        ON wr.wr_returned_date_sk = d_store.d_date_sk                                   -- join 4
    JOIN time_dim t_web
        ON wr.wr_returned_time_sk = t_web.t_time_sk                                     -- join 5
    JOIN reason r_web
        ON wr.wr_reason_sk = r_web.r_reason_sk                                          -- join 6
    CROSS JOIN (SELECT d_year FROM date_dim WHERE d_year IN (2000, 2001)) dy           -- join 7
    CROSS JOIN (VALUES 1, 2, 3) AS v(k)                                                -- join 8
    JOIN date_dim d_extra
        ON sra.sr_returned_date_sk = d_extra.d_date_sk                                 -- join 9
    GROUP BY
        CUBE (r_store.r_reason_desc, d_store.d_year, dy.d_year, v.k),
        d_store.d_weekend,
        t_store.t_hour
)

SELECT *
FROM (
    SELECT
        *,
        ROW_NUMBER() OVER (PARTITION BY r_reason_desc, d_year ORDER BY total_return_amt DESC) AS rn
    FROM base
) final
WHERE rn <= 5
ORDER BY r_reason_desc, d_year, total_return_amt DESC
LIMIT 100
