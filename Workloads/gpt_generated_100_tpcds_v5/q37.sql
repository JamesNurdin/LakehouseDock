WITH sales AS (
    SELECT
        cs.cs_sold_date_sk AS date_sk,
        hd.hd_income_band_sk,
        cs.cs_net_paid_inc_ship AS amount,
        ROW_NUMBER() OVER (PARTITION BY hd.hd_income_band_sk ORDER BY cs.cs_net_paid_inc_ship DESC) AS rn,
        'sale' AS record_type
    FROM catalog_sales cs
    JOIN household_demographics hd
      ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    WHERE cs.cs_quantity > 1
      AND hd.hd_vehicle_count >= 2
      AND cs.cs_net_paid_inc_ship > (
          SELECT AVG(cs2.cs_net_paid_inc_ship)
          FROM catalog_sales cs2
          WHERE cs2.cs_quantity > 0
      )
),
returns AS (
    SELECT
        sr.sr_returned_date_sk AS date_sk,
        hd.hd_income_band_sk,
        sr.sr_net_loss AS amount,
        ROW_NUMBER() OVER (PARTITION BY hd.hd_income_band_sk ORDER BY sr.sr_net_loss DESC) AS rn,
        'return' AS record_type
    FROM store_returns sr
    JOIN household_demographics hd
      ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN reason r
      ON sr.sr_reason_sk = r.r_reason_sk
    WHERE sr.sr_return_quantity > 0
      AND r.r_reason_desc LIKE '%defect%'
      AND hd.hd_income_band_sk IN (7, 10, 14)
)
SELECT
    combined.date_sk,
    combined.hd_income_band_sk,
    combined.amount,
    combined.rn,
    combined.record_type
FROM (
    SELECT date_sk, hd_income_band_sk, amount, rn, record_type FROM sales
    UNION ALL
    SELECT date_sk, hd_income_band_sk, amount, rn, record_type FROM returns
) AS combined
ORDER BY combined.rn
LIMIT 100
