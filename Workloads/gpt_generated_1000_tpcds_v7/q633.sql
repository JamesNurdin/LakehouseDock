WITH returns_by_store_year AS (
    SELECT
        s.s_store_id,
        d.d_year,
        SUM(sr.sr_return_amt_inc_tax) AS total_return_inc_tax,
        COUNT(*) AS return_cnt
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN catalog_returns cr ON d.d_date_sk = cr.cr_returned_date_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN web_site ws ON ws.web_open_date_sk = d.d_date_sk
    WHERE s.s_state = 'CA'
      AND i.i_brand = 'Brand#23'
      AND d.d_year BETWEEN 1998 AND 2000
      AND sm.sm_carrier = 'DHL'
      AND cd.cd_education_status = 'Advanced Degree'
    GROUP BY s.s_store_id, d.d_year
)
SELECT
    year,
    AVG(total_return_inc_tax) AS avg_store_return,
    SUM(return_cnt) AS total_returns
FROM (
    SELECT d_year AS year, total_return_inc_tax, return_cnt
    FROM returns_by_store_year
) agg
WHERE total_return_inc_tax > 1000
GROUP BY year
HAVING AVG(total_return_inc_tax) > 5000
ORDER BY year DESC
