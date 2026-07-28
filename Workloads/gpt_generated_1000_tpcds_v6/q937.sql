WITH filtered AS (
    SELECT
        cc.cc_call_center_id,
        concat(cc.cc_state, '-', cc.cc_city) AS location,
        td.t_hour,
        cr.cr_net_loss,
        hd.hd_income_band_sk,
        cp.cp_description,
        cp.cp_type,
        cc.cc_name,
        cc.cc_zip
    FROM catalog_returns cr
    JOIN catalog_sales cs ON cr.cr_order_number = cs.cs_order_number
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN time_dim td ON cr.cr_returned_time_sk = td.t_time_sk
    JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    WHERE regexp_like(cp.cp_description, '(?i)electronics')
      AND cc.cc_name LIKE 'A%'
)
SELECT
    f.cc_call_center_id,
    f.location,
    f.t_hour,
    SUM(f.cr_net_loss) AS total_net_loss,
    COUNT(*) AS returns_cnt,
    CASE WHEN SUM(f.cr_net_loss) > 1000 THEN 'HIGH' ELSE 'LOW' END AS loss_category,
    (
        SELECT avg(cr2.cr_net_loss)
        FROM catalog_returns cr2
        JOIN household_demographics hd2 ON cr2.cr_refunded_hdemo_sk = hd2.hd_demo_sk
        WHERE hd2.hd_income_band_sk = f.hd_income_band_sk
    ) AS avg_income_band_net_loss,
    regexp_extract(f.cp_type, '(\\d+)', 1) AS type_number,
    CASE WHEN substring(f.cc_zip, 1, 2) = '94' THEN 'West' ELSE 'Other' END AS region
FROM filtered f
GROUP BY
    f.cc_call_center_id,
    f.location,
    f.t_hour,
    f.hd_income_band_sk,
    f.cp_type,
    f.cc_zip
HAVING SUM(f.cr_net_loss) > 0
ORDER BY total_net_loss DESC
LIMIT 100
