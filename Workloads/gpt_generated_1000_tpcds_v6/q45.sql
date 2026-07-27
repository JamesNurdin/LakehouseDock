WITH refunded_hdemo_stats AS (
    SELECT
        hd_demo_sk,
        hd_income_band_sk,
        SUM(wr_return_amt) AS total_return_amount,
        COUNT(*) AS return_cnt
    FROM web_returns
    JOIN household_demographics
        ON web_returns.wr_refunded_hdemo_sk = household_demographics.hd_demo_sk
    WHERE wr_return_amt > 500
    GROUP BY hd_demo_sk, hd_income_band_sk
)
SELECT
    combined.i_item_id,
    combined.i_brand,
    combined.i_manufact,
    combined.total_return_amount,
    combined.return_cnt,
    combined.avg_price_same_manufact,
    combined.brand_rank
FROM (
    SELECT
        i.i_item_id,
        i.i_brand,
        i.i_manufact,
        SUM(wr.wr_return_amt) AS total_return_amount,
        COUNT(*) AS return_cnt,
        (SELECT AVG(i2.i_current_price)
         FROM item i2
         WHERE i2.i_manufact_id = i.i_manufact_id) AS avg_price_same_manufact,
        ROW_NUMBER() OVER (PARTITION BY i.i_brand ORDER BY SUM(wr.wr_return_amt) DESC) AS brand_rank,
        hd.hd_demo_sk
    FROM web_returns wr
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    JOIN household_demographics hd ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    WHERE hd.hd_vehicle_count >= 1
      AND i.i_class_id IN (2, 12)
      AND EXISTS (
          SELECT 1
          FROM refunded_hdemo_stats r
          WHERE r.hd_demo_sk = hd.hd_demo_sk
            AND r.total_return_amount > 1000
      )
    GROUP BY i.i_item_id, i.i_brand, i.i_manufact, i.i_manufact_id, hd.hd_demo_sk

    UNION ALL

    SELECT
        i.i_item_id,
        i.i_brand,
        i.i_manufact,
        SUM(wr.wr_return_amt) AS total_return_amount,
        COUNT(*) AS return_cnt,
        (SELECT AVG(i2.i_current_price)
         FROM item i2
         WHERE i2.i_manufact_id = i.i_manufact_id) AS avg_price_same_manufact,
        ROW_NUMBER() OVER (PARTITION BY i.i_brand ORDER BY SUM(wr.wr_return_amt) DESC) AS brand_rank,
        hd.hd_demo_sk
    FROM web_returns wr
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    JOIN household_demographics hd ON wr.wr_returning_hdemo_sk = hd.hd_demo_sk
    WHERE hd.hd_dep_count = 0
      AND i.i_category_id = 5
      AND EXISTS (
          SELECT 1
          FROM refunded_hdemo_stats r
          WHERE r.hd_demo_sk = hd.hd_demo_sk
            AND r.total_return_amount > 1000
      )
    GROUP BY i.i_item_id, i.i_brand, i.i_manufact, i.i_manufact_id, hd.hd_demo_sk
) AS combined
ORDER BY combined.total_return_amount DESC
LIMIT 100
