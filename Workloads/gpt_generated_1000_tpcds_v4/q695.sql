WITH returns_base AS (
    SELECT
        sr.sr_store_sk,
        sr.sr_returned_date_sk,
        sr.sr_reason_sk,
        sr.sr_hdemo_sk,
        sr.sr_net_loss
    FROM store_returns sr
    WHERE sr.sr_net_loss > 0
)
SELECT
    d.d_year,
    d.d_month_seq,
    s.s_store_name,
    SUM(rb.sr_net_loss) AS total_net_loss,
    regexp_extract(r.r_reason_desc, '(\\d+)', 1) AS reason_code
FROM returns_base rb
JOIN date_dim d
    ON rb.sr_returned_date_sk = d.d_date_sk
JOIN store s
    ON rb.sr_store_sk = s.s_store_sk
JOIN reason r
    ON rb.sr_reason_sk = r.r_reason_sk
WHERE
    s.s_city LIKE 'San %'
    AND regexp_like(r.r_reason_desc, '(?i)damage|defect')
    AND EXISTS (
        SELECT 1
        FROM household_demographics hd
        JOIN income_band ib
            ON hd.hd_income_band_sk = ib.ib_income_band_sk
        WHERE hd.hd_demo_sk = rb.sr_hdemo_sk
          AND ib.ib_lower_bound >= 80000
    )
GROUP BY
    d.d_year,
    d.d_month_seq,
    s.s_store_name,
    regexp_extract(r.r_reason_desc, '(\\d+)', 1)
ORDER BY total_net_loss DESC
LIMIT 100
