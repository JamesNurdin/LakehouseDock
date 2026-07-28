WITH filtered_returns AS (
    SELECT
        cr.cr_net_loss,
        cr.cr_warehouse_sk,
        cr.cr_reason_sk,
        cr.cr_refunded_hdemo_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        r.r_reason_desc,
        w.w_city
    FROM catalog_returns cr
    JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    JOIN household_demographics hd
        ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    WHERE ib.ib_lower_bound > 40000
      AND regexp_like(r.r_reason_desc, '(?i)damage|defect')
      AND w.w_city LIKE 'A%'
)
SELECT
    ib_lower_bound,
    ib_upper_bound,
    regexp_extract(r_reason_desc, '^([A-Za-z]+)', 1) AS reason_root_word,
    CONCAT('City: ', w_city) AS city_label,
    SUM(cr_net_loss) AS total_net_loss,
    COUNT(*) AS returns_count
FROM filtered_returns
GROUP BY
    ib_lower_bound,
    ib_upper_bound,
    regexp_extract(r_reason_desc, '^([A-Za-z]+)', 1),
    CONCAT('City: ', w_city)
ORDER BY total_net_loss DESC
LIMIT 20
