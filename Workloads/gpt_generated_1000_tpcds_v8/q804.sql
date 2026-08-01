WITH sampled_returns AS (
        SELECT *
        FROM store_returns TABLESAMPLE BERNOULLI (10)
    ),
    eligible_returns AS (
        SELECT *
        FROM sampled_returns
        WHERE sr_return_quantity > 0
          AND sr_return_amt > 0
    ),
    valid_store_keys AS (
        SELECT sr.sr_store_sk
        FROM eligible_returns sr
        EXCEPT
        SELECT sr.sr_store_sk
        FROM eligible_returns sr
        JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
        WHERE r.r_reason_desc LIKE '%damaged%'
    ),
    filtered_returns AS (
        SELECT *
        FROM eligible_returns
        WHERE sr_store_sk IN (SELECT sr_store_sk FROM valid_store_keys)
    )
SELECT
    s.s_state,
    i.i_category,
    SUM(fr.sr_return_amt) AS total_return_amount,
    COUNT(*) AS return_cnt,
    AVG(fr.sr_return_amt) AS avg_return_amt,
    MIN(fr.sr_return_amt) AS min_return_amt,
    MAX(fr.sr_return_amt) AS max_return_amt,
    SUM(SUM(fr.sr_return_amt)) OVER (ORDER BY s.s_state, i.i_category ROWS UNBOUNDED PRECEDING) AS running_total_return
FROM filtered_returns fr
JOIN store s ON fr.sr_store_sk = s.s_store_sk
JOIN item i ON fr.sr_item_sk = i.i_item_sk
JOIN customer_demographics cd ON fr.sr_cdemo_sk = cd.cd_demo_sk
JOIN reason r ON fr.sr_reason_sk = r.r_reason_sk
CROSS JOIN LATERAL (
        SELECT p.p_promo_id, p.p_cost
        FROM promotion p
        WHERE p.p_item_sk = i.i_item_sk
          AND p.p_channel_email = 'Y'
        ORDER BY p.p_cost DESC
        LIMIT 1
    ) promo
WHERE cd.cd_gender = 'M'
  AND cd.cd_education_status = 'College'
  AND i.i_brand = 'BrandX'
  AND i.i_color = 'Red'
  AND s.s_state = 'CA'
  AND r.r_reason_desc NOT LIKE '%damaged%'
GROUP BY ROLLUP (s.s_state, i.i_category)
ORDER BY s.s_state, i.i_category
OFFSET 0 LIMIT 100
