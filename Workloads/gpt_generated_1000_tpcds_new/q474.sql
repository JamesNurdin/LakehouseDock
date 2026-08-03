WITH sampled_returns AS (
    SELECT *
    FROM store_returns TABLESAMPLE BERNOULLI (10)
    WHERE sr_return_quantity > 0
      AND sr_return_amt > 10
      AND sr_return_tax >= 0
),
high_return_stores AS (
    SELECT sr_store_sk
    FROM sampled_returns
    GROUP BY sr_store_sk
    HAVING SUM(sr_return_amt) > 5000
),
target_store_keys AS (
    SELECT sr_store_sk
    FROM high_return_stores
    EXCEPT
    SELECT s_store_sk
    FROM store
    WHERE s_state = 'CA'
)
SELECT
    s.s_store_name,
    i.i_category,
    cd.cd_gender,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    cat_stats.category_avg_price,
    SUM(sr.sr_return_amt) AS total_return_amt,
    AVG(sr.sr_return_amt_inc_tax) AS avg_return_inc_tax,
    COUNT(*) AS return_cnt,
    MIN(sr.sr_return_quantity) AS min_qty,
    MAX(sr.sr_return_quantity) AS max_qty,
    CASE
        WHEN SUM(sr.sr_return_amt) > 10000 THEN 'Very High'
        WHEN SUM(sr.sr_return_amt) > 5000 THEN 'High'
        ELSE 'Moderate'
    END AS return_level
FROM sampled_returns sr
JOIN item i
    ON sr.sr_item_sk = i.i_item_sk
JOIN customer_demographics cd
    ON sr.sr_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd
    ON sr.sr_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN store s
    ON sr.sr_store_sk = s.s_store_sk
JOIN target_store_keys tsk
    ON sr.sr_store_sk = tsk.sr_store_sk
LEFT JOIN LATERAL (
    SELECT AVG(i2.i_current_price) AS category_avg_price
    FROM item i2
    WHERE i2.i_category = i.i_category
) cat_stats ON TRUE
WHERE cd.cd_gender = 'M'
  AND cd.cd_education_status = 'College'
  AND hd.hd_vehicle_count >= 1
  AND i.i_current_price BETWEEN 10 AND 200
  AND s.s_market_id IN (1, 3, 5)
GROUP BY
    s.s_store_name,
    i.i_category,
    cd.cd_gender,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    cat_stats.category_avg_price
HAVING COUNT(*) >= 10
ORDER BY total_return_amt DESC
LIMIT 100
