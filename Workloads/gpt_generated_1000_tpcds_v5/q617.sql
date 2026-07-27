WITH sr_base AS (
    SELECT
        sr.sr_store_sk,
        s.s_store_name,
        sr.sr_item_sk,
        i.i_current_price,
        sr.sr_return_quantity,
        sr.sr_return_amt,
        sr.sr_cdemo_sk,
        cd.cd_marital_status,
        sr.sr_hdemo_sk,
        hd.hd_income_band_sk,
        hd.hd_vehicle_count
    FROM store_returns sr
    JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    JOIN item i
        ON sr.sr_item_sk = i.i_item_sk
    JOIN customer_demographics cd
        ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
        ON sr.sr_hdemo_sk = hd.hd_demo_sk
),
overall_avg AS (
    SELECT AVG(sr_return_amt) AS avg_return_amt
    FROM store_returns
)
SELECT
    sr_base.s_store_name,
    'Married' AS customer_category,
    SUM(sr_base.sr_return_amt) AS total_return_amount,
    AVG(sr_base.sr_return_quantity) AS avg_return_qty,
    oa.avg_return_amt AS overall_avg_return_amt
FROM sr_base
JOIN overall_avg oa ON 1 = 1
WHERE sr_base.cd_marital_status = 'M'
  AND sr_base.i_current_price > 100
GROUP BY sr_base.s_store_name, oa.avg_return_amt

UNION ALL

SELECT
    sr_base.s_store_name,
    'HighIncome' AS customer_category,
    SUM(sr_base.sr_return_amt) AS total_return_amount,
    AVG(sr_base.sr_return_quantity) AS avg_return_qty,
    oa.avg_return_amt AS overall_avg_return_amt
FROM sr_base
JOIN overall_avg oa ON 1 = 1
WHERE sr_base.hd_income_band_sk IN (
        SELECT hd_income_band_sk
        FROM household_demographics
        WHERE hd_vehicle_count >= 2
    )
  AND EXISTS (
        SELECT 1
        FROM inventory inv
        WHERE inv.inv_item_sk = sr_base.sr_item_sk
          AND inv.inv_quantity_on_hand > 0
    )
GROUP BY sr_base.s_store_name, oa.avg_return_amt

ORDER BY s_store_name, customer_category
