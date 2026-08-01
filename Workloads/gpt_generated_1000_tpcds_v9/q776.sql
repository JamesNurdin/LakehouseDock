WITH filtered_returns AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_returned_time_sk,
        cr.cr_return_quantity,
        cr.cr_return_amount,
        cr.cr_net_loss,
        cr.cr_ship_mode_sk,
        cr.cr_reason_sk,
        cp.cp_catalog_page_id,
        cp.cp_description,
        CAST(regexp_extract(cp.cp_catalog_page_id, '\\d+', 0) AS integer) AS catalog_page_num,
        sm.sm_carrier,
        sm.sm_code,
        r.r_reason_desc,
        td.t_time_id,
        td.t_am_pm,
        concat(td.t_time_id, '-', td.t_am_pm) AS time_label
    FROM catalog_returns cr
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN time_dim td ON cr.cr_returned_time_sk = td.t_time_sk
    WHERE regexp_like(cp.cp_description, '(?i)special')
      AND sm.sm_carrier LIKE 'G%'
      AND NOT regexp_like(r.r_reason_desc, '(?i)late')
)
SELECT
    fr.sm_carrier,
    fr.r_reason_desc,
    fr.catalog_page_num,
    COUNT(*) AS return_count,
    SUM(fr.cr_return_amount) AS total_return_amount,
    SUM(fr.cr_net_loss) AS total_net_loss,
    (
        SELECT COUNT(DISTINCT cr2.cr_returning_customer_sk)
        FROM catalog_returns cr2
        JOIN ship_mode sm2 ON cr2.cr_ship_mode_sk = sm2.sm_ship_mode_sk
        WHERE sm2.sm_carrier = fr.sm_carrier
    ) AS distinct_customers_per_ship_mode
FROM filtered_returns fr
GROUP BY ROLLUP (fr.sm_carrier, fr.r_reason_desc, fr.catalog_page_num)
ORDER BY
    fr.sm_carrier ASC NULLS LAST,
    fr.r_reason_desc ASC NULLS LAST,
    fr.catalog_page_num ASC NULLS LAST
