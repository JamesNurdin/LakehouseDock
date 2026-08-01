WITH store_returns_agg AS (
    SELECT
        i.i_item_id AS i_item_id,
        i.i_product_name AS i_product_name,
        r.r_reason_desc AS r_reason_desc,
        SUM(sr.sr_return_amt_inc_tax) AS total_return_amount,
        COUNT(*) AS return_cnt,
        'store' AS channel
    FROM store_returns sr
    JOIN time_dim t
        ON sr.sr_return_time_sk = t.t_time_sk
    JOIN item i
        ON sr.sr_item_sk = i.i_item_sk
    JOIN reason r
        ON sr.sr_reason_sk = r.r_reason_sk
    JOIN household_demographics hd
        ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE ib.ib_upper_bound >= (SELECT MAX(ib2.ib_upper_bound) FROM income_band ib2) * 0.8
      AND t.t_hour >= 12
    GROUP BY i.i_item_id, i.i_product_name, r.r_reason_desc
),
web_returns_agg AS (
    SELECT
        i.i_item_id AS i_item_id,
        i.i_product_name AS i_product_name,
        r.r_reason_desc AS r_reason_desc,
        SUM(wr.wr_return_amt_inc_tax) AS total_return_amount,
        COUNT(*) AS return_cnt,
        'web' AS channel
    FROM web_returns wr
    JOIN time_dim t
        ON wr.wr_returned_time_sk = t.t_time_sk
    JOIN item i
        ON wr.wr_item_sk = i.i_item_sk
    JOIN reason r
        ON wr.wr_reason_sk = r.r_reason_sk
    JOIN household_demographics hd
        ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE ib.ib_upper_bound >= (SELECT MAX(ib2.ib_upper_bound) FROM income_band ib2) * 0.8
      AND EXISTS (
          SELECT 1
          FROM reason r2
          WHERE r2.r_reason_sk = wr.wr_reason_sk
            AND r2.r_reason_desc LIKE '%Defective%')
      AND t.t_hour >= 12
    GROUP BY i.i_item_id, i.i_product_name, r.r_reason_desc
)
SELECT
    row_number() OVER (ORDER BY total_return_amount DESC) AS row_num,
    item_id,
    product_name,
    reason_desc,
    channel,
    total_return_amount,
    return_cnt
FROM (
    SELECT
        i_item_id AS item_id,
        i_product_name AS product_name,
        r_reason_desc AS reason_desc,
        total_return_amount,
        return_cnt,
        channel
    FROM store_returns_agg
    UNION ALL
    SELECT
        i_item_id,
        i_product_name,
        r_reason_desc,
        total_return_amount,
        return_cnt,
        channel
    FROM web_returns_agg
) AS combined
ORDER BY total_return_amount DESC
LIMIT 100
