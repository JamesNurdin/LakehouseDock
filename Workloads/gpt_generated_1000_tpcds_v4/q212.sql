WITH distinct_returns AS (
    SELECT DISTINCT
        cr_returned_date_sk,
        cr_returned_time_sk,
        cr_return_amount,
        cr_net_loss
    FROM catalog_returns
    WHERE cr_return_amount > 0
      AND cr_net_loss IS NOT NULL
),
agg_returns AS (
    SELECT
        cr_returned_date_sk,
        cr_returned_time_sk,
        SUM(cr_return_amount) AS total_return_amount,
        SUM(cr_net_loss) AS total_net_loss,
        COUNT(*) AS return_cnt,
        CASE WHEN SUM(cr_return_amount) > 1000 THEN 'HIGH' ELSE 'LOW' END AS amount_category
    FROM distinct_returns
    GROUP BY cr_returned_date_sk, cr_returned_time_sk
),
joined AS (
    SELECT
        d.d_year,
        d.d_qoy,
        t.t_shift,
        ar.amount_category,
        ar.total_return_amount,
        ar.total_net_loss,
        ar.return_cnt
    FROM agg_returns ar
    JOIN date_dim d
        ON ar.cr_returned_date_sk = d.d_date_sk
    JOIN time_dim t
        ON ar.cr_returned_time_sk = t.t_time_sk
    WHERE d.d_year = 2001
      AND d.d_qoy = 2
      AND t.t_shift = 'second'
)
SELECT
    d_year,
    t_shift,
    amount_category,
    SUM(total_return_amount) AS sum_return_amount,
    AVG(total_net_loss) AS avg_net_loss,
    SUM(return_cnt) AS total_returns
FROM joined
GROUP BY d_year, t_shift, amount_category
HAVING SUM(total_return_amount) > 5000
ORDER BY sum_return_amount DESC
LIMIT 100
