WITH base AS (
    SELECT
        r.r_reason_desc,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        hd.hd_vehicle_count,
        sr.sr_return_amt,
        sr.sr_return_quantity,
        ws.web_state
    FROM catalog_page cp
    JOIN date_dim d
        ON cp.cp_end_date_sk = d.d_date_sk
    JOIN store_returns sr
        ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN household_demographics hd
        ON hd.hd_demo_sk = sr.sr_hdemo_sk
    JOIN income_band ib
        ON ib.ib_income_band_sk = hd.hd_income_band_sk
    JOIN reason r
        ON r.r_reason_sk = sr.sr_reason_sk
    JOIN web_returns wr
        ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN web_site ws
        ON ws.web_open_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND d.d_month_seq BETWEEN 1200 AND 1300
      AND cp.cp_catalog_number IN (2, 9, 13)
      AND ib.ib_lower_bound >= 20000
      AND hd.hd_vehicle_count >= 1
      AND r.r_reason_desc LIKE '%price%'
      AND ws.web_state = 'CA'
      AND sr.sr_return_amt > 100
),
agg AS (
    SELECT
        r_reason_desc,
        SUM(sr_return_amt) AS total_return_amt,
        COUNT(*) AS cnt,
        SUM(sr_return_quantity) AS total_qty
    FROM base
    GROUP BY r_reason_desc
    HAVING SUM(sr_return_amt) > 5000
)
SELECT
    AVG(total_return_amt) AS avg_total_return_amt,
    SUM(cnt) AS total_returns,
    MAX(total_return_amt) AS max_total_return_amt
FROM agg
