WITH high_income_warehouse AS (
    SELECT DISTINCT cr.cr_warehouse_sk AS warehouse_sk
    FROM catalog_returns cr
    JOIN household_demographics hd
        ON cr.cr_returning_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE ib.ib_upper_bound > 100000
      AND cr.cr_return_amount > 100
),
low_income_warehouse AS (
    SELECT DISTINCT cs.cs_warehouse_sk AS warehouse_sk
    FROM catalog_sales cs
    JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE ib.ib_lower_bound <= 50000
      AND cs.cs_quantity > 5
)

SELECT w.w_warehouse_name,
       'Return' AS record_type,
       SUM(cr.cr_net_loss) AS total_amount
FROM catalog_returns cr
JOIN high_income_warehouse hi
    ON cr.cr_warehouse_sk = hi.warehouse_sk
JOIN warehouse w
    ON cr.cr_warehouse_sk = w.w_warehouse_sk
GROUP BY w.w_warehouse_name

UNION ALL

SELECT w.w_warehouse_name,
       'Sale' AS record_type,
       SUM(cs.cs_net_profit) AS total_amount
FROM catalog_sales cs
JOIN low_income_warehouse lo
    ON cs.cs_warehouse_sk = lo.warehouse_sk
JOIN warehouse w
    ON cs.cs_warehouse_sk = w.w_warehouse_sk
GROUP BY w.w_warehouse_name

ORDER BY total_amount DESC
LIMIT 100
