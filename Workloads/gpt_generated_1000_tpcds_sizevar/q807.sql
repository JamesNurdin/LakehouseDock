WITH filtered AS (
    SELECT
        i.i_item_sk,
        i.i_category_id,
        i.i_formulation,
        p.p_promo_sk,
        p.p_channel_dmail,
        p.p_response_target,
        sr.sr_store_credit,
        sr.sr_addr_sk,
        sr.sr_return_amt,
        sr.sr_return_quantity
    FROM store_returns sr
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN promotion p ON p.p_item_sk = i.i_item_sk
    WHERE i.i_category_id IN (2, 3, 5)
      AND i.i_formulation LIKE '%thistle%'
      AND p.p_channel_dmail = 'Y'
      AND p.p_response_target >= 1
      AND sr.sr_store_credit > 10
      AND sr.sr_addr_sk NOT IN (1908137, 301129)
),
agg1 AS (
    SELECT
        i_category_id,
        i_formulation,
        COUNT(DISTINCT i_item_sk) AS cnt_items,
        SUM(sr_return_amt) AS total_return_amt,
        AVG(sr_store_credit) AS avg_store_credit
    FROM filtered
    GROUP BY i_category_id, i_formulation
),
agg2 AS (
    SELECT
        i_category_id,
        i_formulation,
        COUNT(*) AS cnt_returns,
        MAX(sr_return_amt) AS max_return_amt,
        MIN(sr_store_credit) AS min_store_credit
    FROM filtered
    GROUP BY i_category_id, i_formulation
),
union_agg AS (
    SELECT
        i_category_id,
        i_formulation,
        cnt_items AS metric,
        total_return_amt AS value
    FROM agg1
    UNION
    SELECT
        i_category_id,
        i_formulation,
        cnt_returns AS metric,
        max_return_amt AS value
    FROM agg2
),
except_set AS (
    SELECT i_category_id FROM union_agg WHERE metric > 10
    EXCEPT
    SELECT i_category_id FROM union_agg WHERE value < 500
),
intersect_set AS (
    SELECT i_category_id FROM union_agg WHERE metric = value
    INTERSECT
    SELECT i_category_id FROM union_agg WHERE metric > 0
)
SELECT
    u.i_category_id,
    u.i_formulation,
    u.metric,
    u.value
FROM union_agg u
WHERE u.i_category_id IN (SELECT i_category_id FROM except_set)
  AND u.i_category_id IN (SELECT i_category_id FROM intersect_set)
ORDER BY u.i_category_id ASC, u.metric DESC
LIMIT 100
