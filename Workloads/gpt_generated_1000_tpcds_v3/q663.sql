WITH store_returns_agg AS (
    SELECT
        i.i_item_id,
        i.i_product_name,
        SUM(sr.sr_return_amt) AS total_return_amount,
        COUNT(*) AS return_cnt,
        'store' AS channel
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE d.d_current_quarter = 'Y'
      AND s.s_country = 'United States'
      AND ib.ib_lower_bound > 30000
    GROUP BY i.i_item_id, i.i_product_name
),
web_returns_agg AS (
    SELECT
        i.i_item_id,
        i.i_product_name,
        SUM(wr.wr_return_amt) AS total_return_amount,
        COUNT(*) AS return_cnt,
        'web' AS channel
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    JOIN household_demographics hd ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE d.d_current_quarter = 'Y'
      AND ib.ib_lower_bound > 30000
    GROUP BY i.i_item_id, i.i_product_name
),
combined_returns AS (
    SELECT i_item_id, i_product_name, total_return_amount, return_cnt, channel
    FROM store_returns_agg
    UNION ALL
    SELECT i_item_id, i_product_name, total_return_amount, return_cnt, channel
    FROM web_returns_agg
)
SELECT
    cr.i_item_id,
    cr.i_product_name,
    SUM(cr.total_return_amount) AS total_return_amount,
    SUM(cr.return_cnt) AS total_return_count,
    COUNT(DISTINCT cr.channel) AS channels_involved,
    (SELECT AVG(i2.i_current_price)
     FROM item i2
     WHERE i2.i_item_id = cr.i_item_id) AS avg_item_price
FROM combined_returns cr
GROUP BY cr.i_item_id, cr.i_product_name
ORDER BY total_return_amount DESC
LIMIT 100
