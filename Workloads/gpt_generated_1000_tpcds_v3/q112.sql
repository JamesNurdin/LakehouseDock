WITH date_filter AS (
    SELECT d_date_sk, d_year
    FROM date_dim
    WHERE d_year = 2001
),
store_agg AS (
    SELECT
        s.s_store_id AS entity_id,
        SUM(sr.sr_net_loss) AS total_amount
    FROM store_returns sr
    JOIN date_filter df ON sr.sr_returned_date_sk = df.d_date_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    WHERE sr.sr_net_loss > 0
      AND EXISTS (
          SELECT 1
          FROM store_returns sr2
          JOIN date_filter df2 ON sr2.sr_returned_date_sk = df2.d_date_sk
          WHERE sr2.sr_store_sk = s.s_store_sk
            AND sr2.sr_net_loss > 500
      )
    GROUP BY s.s_store_id
),
call_center_agg AS (
    SELECT
        cc.cc_call_center_id AS entity_id,
        SUM(cr.cr_return_amount) AS total_amount
    FROM catalog_returns cr
    JOIN date_filter df ON cr.cr_returned_date_sk = df.d_date_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    WHERE cr.cr_return_amount > 0
      AND EXISTS (
          SELECT 1
          FROM catalog_returns cr2
          JOIN date_filter df2 ON cr2.cr_returned_date_sk = df2.d_date_sk
          WHERE cr2.cr_call_center_sk = cc.cc_call_center_sk
            AND cr2.cr_return_amount > 1000
      )
    GROUP BY cc.cc_call_center_id
),
unioned AS (
    SELECT 'Store' AS entity_type, entity_id, total_amount
    FROM store_agg
    UNION ALL
    SELECT 'CallCenter' AS entity_type, entity_id, total_amount
    FROM call_center_agg
)
SELECT
    entity_type,
    entity_id,
    total_amount,
    ROW_NUMBER() OVER (PARTITION BY entity_type ORDER BY total_amount DESC) AS rank_within_type,
    AVG(total_amount) OVER () AS avg_total_amount
FROM unioned
WHERE total_amount > (
    SELECT AVG(total_amount)
    FROM unioned
)
ORDER BY entity_type, rank_within_type
LIMIT 100
