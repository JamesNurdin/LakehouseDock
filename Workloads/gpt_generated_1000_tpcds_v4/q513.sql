/*
Goal: Compare loss metrics for store versus web returns by reason, applying regex and LIKE filters on reason descriptions, extracting words, categorising loss levels with CASE, checking existence of matching web returns, and showing overall loss totals.
*/
WITH
store_agg AS (
    SELECT
        'Store' AS channel,
        s.s_store_id AS store_id,
        r.r_reason_desc AS reason_desc,
        SUM(sr.sr_return_quantity) AS total_qty,
        SUM(sr.sr_net_loss) AS total_loss,
        CASE
            WHEN SUM(sr.sr_net_loss) > 1000 THEN 'HIGH'
            ELSE 'LOW'
        END AS loss_category,
        CONCAT(s.s_store_name, ' - ', r.r_reason_desc) AS label,
        regexp_extract(r.r_reason_desc, '^([A-Za-z]+)', 1) AS reason_first_word
    FROM store_returns sr
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE regexp_like(r.r_reason_desc, '(?i)working')
      AND EXISTS (
          SELECT 1
          FROM web_returns wr
          WHERE wr.wr_reason_sk = sr.sr_reason_sk
            AND wr.wr_return_quantity > 0
      )
    GROUP BY s.s_store_id, s.s_store_name, r.r_reason_desc
),
web_agg AS (
    SELECT
        'Web' AS channel,
        NULL AS store_id,
        r.r_reason_desc AS reason_desc,
        SUM(wr.wr_return_quantity) AS total_qty,
        SUM(wr.wr_net_loss) AS total_loss,
        CASE
            WHEN SUM(wr.wr_net_loss) > 2000 THEN 'VERY HIGH'
            ELSE 'MODERATE'
        END AS loss_category,
        CONCAT('WEB-', r.r_reason_id) AS label,
        regexp_extract(r.r_reason_desc, '([A-Za-z]+)\\s', 1) AS reason_first_word
    FROM web_returns wr
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    WHERE r.r_reason_desc LIKE '%exchange%'
    GROUP BY r.r_reason_desc, r.r_reason_id
),
overall AS (
    SELECT
        (SELECT SUM(sr_net_loss) FROM store_returns) AS store_total_loss,
        (SELECT SUM(wr_net_loss) FROM web_returns)   AS web_total_loss
)
SELECT
    a.channel,
    a.store_id,
    a.reason_desc,
    a.total_qty,
    a.total_loss,
    a.loss_category,
    a.label,
    a.reason_first_word,
    CASE
        WHEN a.channel = 'Store' THEN o.store_total_loss
        ELSE o.web_total_loss
    END AS overall_category_loss
FROM (
    SELECT * FROM store_agg
    UNION ALL
    SELECT * FROM web_agg
) a
CROSS JOIN overall o
ORDER BY a.total_loss DESC
LIMIT 100
