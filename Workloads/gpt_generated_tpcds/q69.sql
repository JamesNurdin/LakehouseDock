WITH sales_agg AS (
    SELECT
        ss.ss_store_sk AS store_sk,
        d.d_year,
        d.d_moy,
        td.t_shift,
        SUM(ss.ss_net_paid) AS total_net_paid,
        SUM(ss.ss_quantity) AS total_quantity
    FROM store_sales ss
    JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim td
        ON ss.ss_sold_time_sk = td.t_time_sk
    WHERE d.d_year = 2001
    GROUP BY ss.ss_store_sk, d.d_year, d.d_moy, td.t_shift
),
returns_agg AS (
    SELECT
        sr.sr_store_sk AS store_sk,
        d.d_year,
        d.d_moy,
        SUM(sr.sr_return_quantity) AS total_return_quantity,
        SUM(sr.sr_return_amt) AS total_return_amount,
        SUM(sr.sr_net_loss) AS total_net_loss
    FROM store_returns sr
    JOIN date_dim d
        ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY sr.sr_store_sk, d.d_year, d.d_moy
)
SELECT
    s.s_store_name,
    sa.d_year,
    sa.d_moy,
    sa.t_shift,
    sa.total_net_paid,
    COALESCE(ra.total_net_loss, 0) AS total_net_loss,
    sa.total_quantity,
    COALESCE(ra.total_return_quantity, 0) AS total_return_quantity,
    CASE
        WHEN sa.total_quantity > 0
        THEN COALESCE(ra.total_return_quantity, 0) * 1.0 / sa.total_quantity
        ELSE 0
    END AS return_rate
FROM sales_agg sa
JOIN store s
    ON sa.store_sk = s.s_store_sk
LEFT JOIN returns_agg ra
    ON sa.store_sk = ra.store_sk
   AND sa.d_year = ra.d_year
   AND sa.d_moy = ra.d_moy
WHERE s.s_closed_date_sk IS NULL
ORDER BY s.s_store_name, sa.d_year, sa.d_moy, sa.t_shift
