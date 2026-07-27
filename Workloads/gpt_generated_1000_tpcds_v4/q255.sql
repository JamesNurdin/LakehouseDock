WITH returns_by_item AS (
    SELECT
        i.i_item_id,
        i.i_brand,
        i.i_category,
        hd.hd_buy_potential,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        SUM(sr.sr_return_amt) AS total_return_amt,
        SUM(sr.sr_return_quantity) AS total_return_qty,
        COUNT(*) AS return_transactions
    FROM store_returns sr
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE sr.sr_returned_date_sk BETWEEN 2451868 AND 2452646
      AND sr.sr_return_amt > 50
      AND i.i_wholesale_cost BETWEEN 1 AND 30
      AND hd.hd_dep_count <= 5
      AND ib.ib_upper_bound <= 50000
    GROUP BY
        i.i_item_id,
        i.i_brand,
        i.i_category,
        hd.hd_buy_potential,
        ib.ib_lower_bound,
        ib.ib_upper_bound
)
SELECT
    rbi.i_item_id,
    rbi.i_brand,
    rbi.i_category,
    rbi.hd_buy_potential,
    rbi.ib_lower_bound,
    rbi.ib_upper_bound,
    rbi.total_return_amt,
    rbi.total_return_qty,
    rbi.return_transactions,
    RANK() OVER (PARTITION BY rbi.i_brand ORDER BY rbi.total_return_amt DESC) AS brand_return_rank,
    CASE
        WHEN rbi.total_return_amt > 1000 THEN 'High'
        WHEN rbi.total_return_amt > 500 THEN 'Medium'
        ELSE 'Low'
    END AS return_level
FROM returns_by_item rbi
ORDER BY rbi.total_return_amt DESC, rbi.i_item_id
LIMIT 100
