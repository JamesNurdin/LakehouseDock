WITH filtered_returns AS (
    SELECT
        sr.sr_store_sk,
        sr.sr_return_time_sk,
        sr.sr_cdemo_sk,
        sr.sr_hdemo_sk,
        sr.sr_reason_sk,
        sr.sr_return_amt,
        sr.sr_return_quantity
    FROM store_returns sr
    WHERE sr.sr_return_quantity > 1
      AND sr.sr_return_amt > 0
      AND sr.sr_return_amt_inc_tax > 0
      AND sr.sr_store_sk IS NOT NULL
      AND sr.sr_return_time_sk IS NOT NULL
),
agg AS (
    SELECT
        s.s_store_name,
        s.s_manager,
        s.s_gmt_offset,
        cd.cd_marital_status,
        cd.cd_dep_employed_count,
        hd.hd_income_band_sk,
        r.r_reason_desc,
        td.t_shift,
        SUM(fr.sr_return_amt) AS total_return_amt,
        COUNT(*) AS return_cnt
    FROM filtered_returns fr
    JOIN store s ON fr.sr_store_sk = s.s_store_sk
    JOIN time_dim td ON fr.sr_return_time_sk = td.t_time_sk
    JOIN customer_demographics cd ON fr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON fr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN reason r ON fr.sr_reason_sk = r.r_reason_sk
    WHERE td.t_shift IN ('first', 'second')
      AND cd.cd_marital_status = 'M'
      AND cd.cd_dep_employed_count >= 1
      AND hd.hd_income_band_sk BETWEEN 3 AND 7
      AND s.s_gmt_offset = -5.00
    GROUP BY
        s.s_store_name,
        s.s_manager,
        s.s_gmt_offset,
        cd.cd_marital_status,
        cd.cd_dep_employed_count,
        hd.hd_income_band_sk,
        r.r_reason_desc,
        td.t_shift
    HAVING SUM(fr.sr_return_amt) > 1000
)
SELECT
    a.s_store_name,
    a.s_manager,
    a.s_gmt_offset,
    a.cd_marital_status,
    a.cd_dep_employed_count,
    a.hd_income_band_sk,
    a.r_reason_desc,
    a.t_shift,
    a.total_return_amt,
    a.return_cnt,
    RANK() OVER (PARTITION BY a.s_manager ORDER BY a.total_return_amt DESC) AS manager_store_rank,
    SUM(a.total_return_amt) OVER (PARTITION BY a.s_manager ORDER BY a.total_return_amt ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cum_return_by_manager
FROM agg a
ORDER BY a.total_return_amt DESC
LIMIT 100
