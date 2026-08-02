WITH
store_agg AS (
    SELECT
        r.r_reason_sk,
        d.d_year,
        SUM(sr.sr_net_loss) AS store_net_loss,
        COUNT(*) AS store_return_cnt,
        REGEXP_EXTRACT(r.r_reason_id, '(A{3,})', 1) AS reason_id_a_block,
        CONCAT(r.r_reason_id, '-', r.r_reason_desc) AS reason_full_key
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    WHERE REGEXP_LIKE(r.r_reason_desc, '(service|Parts)')
        AND r.r_reason_id LIKE 'AAAAAAA%'
        AND hd.hd_buy_potential LIKE '5%'
    GROUP BY r.r_reason_sk, d.d_year, r.r_reason_id, r.r_reason_desc
),
web_agg AS (
    SELECT
        r.r_reason_sk,
        d.d_year,
        SUM(wr.wr_net_loss) AS web_net_loss,
        COUNT(*) AS web_return_cnt,
        REGEXP_EXTRACT(r.r_reason_id, '(A{3,})', 1) AS reason_id_a_block,
        CONCAT(r.r_reason_id, '-', r.r_reason_desc) AS reason_full_key
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    JOIN household_demographics hd ON wr.wr_returning_hdemo_sk = hd.hd_demo_sk
    WHERE REGEXP_LIKE(r.r_reason_desc, '(service|Parts)')
        AND r.r_reason_id LIKE 'AAAAAAA%'
        AND hd.hd_buy_potential LIKE '5%'
    GROUP BY r.r_reason_sk, d.d_year, r.r_reason_id, r.r_reason_desc
),
common_reason_years AS (
    SELECT r_reason_sk, d_year FROM store_agg
    INTERSECT
    SELECT r_reason_sk, d_year FROM web_agg
)
SELECT
    r.r_reason_id,
    r.r_reason_desc,
    s.d_year,
    s.store_net_loss,
    w.web_net_loss,
    s.store_return_cnt,
    w.web_return_cnt,
    s.reason_full_key,
    s.reason_id_a_block,
    SUBSTRING(r.r_reason_desc FROM 1 FOR 30) AS reason_desc_prefix,
    (SELECT AVG(sr2.sr_net_loss) FROM store_returns sr2 WHERE sr2.sr_reason_sk = r.r_reason_sk) AS avg_store_net_loss_all_years,
    (SELECT AVG(wr2.wr_net_loss) FROM web_returns wr2 WHERE wr2.wr_reason_sk = r.r_reason_sk) AS avg_web_net_loss_all_years
FROM common_reason_years cr
JOIN store_agg s ON s.r_reason_sk = cr.r_reason_sk AND s.d_year = cr.d_year
JOIN web_agg w ON w.r_reason_sk = cr.r_reason_sk AND w.d_year = cr.d_year
JOIN reason r ON r.r_reason_sk = cr.r_reason_sk
WHERE REGEXP_LIKE(r.r_reason_desc, '^No service')
    AND EXISTS (
        SELECT 1
        FROM catalog_page cp
        JOIN date_dim d2 ON cp.cp_start_date_sk = d2.d_date_sk
        WHERE d2.d_year = s.d_year
          AND REGEXP_LIKE(cp.cp_description, '(sale|discount)')
          AND cp.cp_department LIKE '%Elect%'
    )
ORDER BY s.store_net_loss DESC
LIMIT 100
