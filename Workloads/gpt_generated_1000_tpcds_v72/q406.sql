WITH catalog_ret AS (
    SELECT
        cr.cr_returned_date_sk AS date_sk,
        cr.cr_net_loss AS net_loss,
        sm.sm_type AS ship_mode_type,
        r.r_reason_desc AS reason_desc
    FROM catalog_returns cr
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE regexp_like(cp.cp_description, '(?i)goods')
      AND sm.sm_contract LIKE 'A%'
      AND substring(sm.sm_type, 1, 3) = 'EXP'
),
web_ret AS (
    SELECT
        wr.wr_returned_date_sk AS date_sk,
        wr.wr_net_loss AS net_loss,
        CAST(NULL AS varchar) AS ship_mode_type,
        r.r_reason_desc AS reason_desc
    FROM web_returns wr
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    WHERE wr.wr_return_amt_inc_tax > 1000
      AND r.r_reason_desc LIKE '%damaged%'
)
SELECT
    ship_mode_type,
    reason_desc,
    COUNT(*) AS return_cnt,
    SUM(net_loss) AS total_net_loss
FROM (
    SELECT * FROM catalog_ret
    UNION ALL
    SELECT * FROM web_ret
) AS combined
GROUP BY ship_mode_type, reason_desc
HAVING SUM(net_loss) > 5000
ORDER BY total_net_loss DESC
LIMIT 100
