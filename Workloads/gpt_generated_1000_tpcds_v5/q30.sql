WITH catalog_warehouse AS (
    SELECT
        cr.cr_warehouse_sk,
        cr.cr_reason_sk,
        cr.cr_return_amount,
        cr.cr_net_loss,
        w.w_state,
        w.w_zip,
        r.r_reason_desc
    FROM catalog_returns cr
    JOIN warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    WHERE w.w_state = 'MN'
      AND w.w_zip = '44593'
      AND cr.cr_return_amount > 100
      AND r.r_reason_desc = 'Package was damaged'
)
SELECT
    cw.w_state,
    cw.r_reason_desc,
    COUNT(*) AS catalog_return_cnt,
    SUM(cw.cr_return_amount) AS total_catalog_return_amount,
    AVG(cw.cr_net_loss) AS avg_catalog_net_loss,
    COALESCE(SUM(sr.sr_return_amt), 0) AS total_store_return_amount,
    COUNT(sr.sr_ticket_number) AS store_return_cnt
FROM catalog_warehouse cw
LEFT JOIN store_returns sr
    ON sr.sr_reason_sk = cw.cr_reason_sk
GROUP BY cw.w_state, cw.r_reason_desc
ORDER BY total_catalog_return_amount DESC
LIMIT 100
