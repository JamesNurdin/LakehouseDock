WITH cr_join AS (
    SELECT
        cr.cr_return_amount,
        cr.cr_net_loss,
        w.w_warehouse_name,
        r.r_reason_desc AS r_reason_desc,
        split(r.r_reason_desc, ' ') AS reason_words
    FROM catalog_returns cr
    JOIN customer c_ret ON cr.cr_returning_customer_sk = c_ret.c_customer_sk
    JOIN customer_demographics cd_ret ON cr.cr_returning_cdemo_sk = cd_ret.cd_demo_sk
    JOIN household_demographics hd_ret ON cr.cr_returning_hdemo_sk = hd_ret.hd_demo_sk
    JOIN customer_address ca_ret ON cr.cr_returning_addr_sk = ca_ret.ca_address_sk
    JOIN customer c_ref ON cr.cr_refunded_customer_sk = c_ref.c_customer_sk
    JOIN customer_demographics cd_ref ON cr.cr_refunded_cdemo_sk = cd_ref.cd_demo_sk
    JOIN household_demographics hd_ref ON cr.cr_refunded_hdemo_sk = hd_ref.hd_demo_sk
    JOIN customer_address ca_ref ON cr.cr_refunded_addr_sk = ca_ref.ca_address_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE EXISTS (
        SELECT 1
        FROM reason r2
        WHERE r2.r_reason_sk = cr.cr_reason_sk
          AND r2.r_reason_desc LIKE '%price%'
    )
),
sr_join AS (
    SELECT
        sr.sr_return_amt,
        sr.sr_net_loss,
        s.s_store_name,
        r.r_reason_desc AS r_reason_desc,
        split(r.r_reason_desc, ' ') AS reason_words
    FROM store_returns sr
    JOIN customer c_sr ON sr.sr_customer_sk = c_sr.c_customer_sk
    JOIN customer_demographics cd_sr ON sr.sr_cdemo_sk = cd_sr.cd_demo_sk
    JOIN household_demographics hd_sr ON sr.sr_hdemo_sk = hd_sr.hd_demo_sk
    JOIN customer_address ca_sr ON sr.sr_addr_sk = ca_sr.ca_address_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
)
SELECT
    'catalog' AS source,
    cr_join.w_warehouse_name AS location_name,
    cr_join.r_reason_desc AS reason,
    SUM(cr_join.cr_return_amount) AS total_return_amount,
    COUNT(*) AS return_count,
    AVG(cr_join.cr_net_loss) AS avg_net_loss,
    ROW_NUMBER() OVER (
        PARTITION BY cr_join.w_warehouse_name
        ORDER BY SUM(cr_join.cr_return_amount) DESC
    ) AS location_rank,
    rw.reason_word AS reason_word
FROM cr_join
CROSS JOIN UNNEST(cr_join.reason_words) AS rw(reason_word)
GROUP BY cr_join.w_warehouse_name, cr_join.r_reason_desc, rw.reason_word
HAVING SUM(cr_join.cr_return_amount) > (SELECT AVG(cr_return_amount) FROM catalog_returns)
UNION DISTINCT
SELECT
    'store' AS source,
    sr_join.s_store_name AS location_name,
    sr_join.r_reason_desc AS reason,
    SUM(sr_join.sr_return_amt) AS total_return_amount,
    COUNT(*) AS return_count,
    AVG(sr_join.sr_net_loss) AS avg_net_loss,
    ROW_NUMBER() OVER (
        PARTITION BY sr_join.s_store_name
        ORDER BY SUM(sr_join.sr_return_amt) DESC
    ) AS location_rank,
    rw2.reason_word AS reason_word
FROM sr_join
CROSS JOIN UNNEST(sr_join.reason_words) AS rw2(reason_word)
GROUP BY sr_join.s_store_name, sr_join.r_reason_desc, rw2.reason_word
HAVING SUM(sr_join.sr_return_amt) > (SELECT AVG(sr_return_amt) FROM store_returns)
ORDER BY total_return_amount DESC
LIMIT 100
