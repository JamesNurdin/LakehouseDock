WITH returns_by_demo_item AS (
    SELECT
        wr.wr_item_sk,
        wr.wr_refunded_hdemo_sk AS hd_demo_sk,
        SUM(wr.wr_return_amt) AS sum_return_amt,
        SUM(wr.wr_return_tax) AS sum_return_tax,
        SUM(wr.wr_return_ship_cost) AS sum_ship_cost,
        COUNT(*) AS return_cnt,
        AVG(wr.wr_return_amt_inc_tax) AS avg_return_amt_inc_tax
    FROM web_returns wr
    GROUP BY wr.wr_item_sk, wr.wr_refunded_hdemo_sk
)
SELECT
    i.i_item_id,
    i.i_product_name,
    i.i_current_price,
    i.i_brand_id,
    hd.hd_buy_potential,
    hd.hd_dep_count,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    rbi.sum_return_amt,
    rbi.return_cnt,
    CASE
        WHEN rbi.sum_return_amt > 2000 THEN 'High'
        WHEN rbi.sum_return_amt > 500 THEN 'Medium'
        ELSE 'Low'
    END AS return_level,
    RANK() OVER (PARTITION BY ib.ib_income_band_sk ORDER BY rbi.sum_return_amt DESC) AS rank_within_income_band,
    AVG(rbi.sum_return_amt) OVER (
        PARTITION BY ib.ib_income_band_sk
        ORDER BY rbi.sum_return_amt
        ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING
    ) AS avg_adjacent_return_amt,
    (
        SELECT AVG(wr2.wr_return_amt)
        FROM web_returns wr2
        WHERE wr2.wr_item_sk = i.i_item_sk
    ) AS overall_avg_return_amt
FROM returns_by_demo_item rbi
JOIN item i ON rbi.wr_item_sk = i.i_item_sk
JOIN household_demographics hd ON rbi.hd_demo_sk = hd.hd_demo_sk
JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
WHERE
    i.i_current_price > 100
    AND i.i_brand_id = 1
    AND ib.ib_upper_bound >= 80000
    AND hd.hd_buy_potential = '1001-5000'
    AND rbi.sum_return_tax > 10
    AND rbi.sum_ship_cost BETWEEN 500 AND 1500
ORDER BY rbi.sum_return_amt DESC, i.i_item_id ASC
LIMIT 100
