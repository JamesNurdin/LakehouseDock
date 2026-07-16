WITH address_income AS (
    SELECT
        ca.ca_county,
        ca.ca_state,
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM customer_address ca
    JOIN income_band ib
      ON TRY_CAST(ca.ca_zip AS INTEGER) = ib.ib_income_band_sk
    WHERE ca.ca_state IN ('CA', 'TX', 'NY')
),
 demog_agg AS (
    SELECT
        ib.ib_income_band_sk,
        COUNT(*) AS demo_cnt,
        SUM(cd.cd_purchase_estimate) AS total_purchase_est,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_est
    FROM customer_demographics cd
    JOIN income_band ib
      ON cd.cd_purchase_estimate BETWEEN ib.ib_lower_bound AND ib.ib_upper_bound
    GROUP BY ib.ib_income_band_sk
),
 inv_agg AS (
    SELECT
        ib.ib_income_band_sk,
        SUM(inv.inv_quantity_on_hand) AS total_quantity,
        COUNT(DISTINCT inv.inv_item_sk) AS distinct_items
    FROM inventory inv
    JOIN income_band ib
      ON inv.inv_quantity_on_hand BETWEEN ib.ib_lower_bound AND ib.ib_upper_bound
    GROUP BY ib.ib_income_band_sk
)
SELECT
    ai.ca_county,
    ai.ca_state,
    ai.ib_income_band_sk,
    da.demo_cnt,
    da.total_purchase_est,
    ia.total_quantity,
    ia.distinct_items,
    RANK() OVER (PARTITION BY ai.ib_income_band_sk ORDER BY ia.total_quantity DESC) AS quantity_rank
FROM address_income ai
LEFT JOIN demog_agg da
  ON ai.ib_income_band_sk = da.ib_income_band_sk
LEFT JOIN inv_agg ia
  ON ai.ib_income_band_sk = ia.ib_income_band_sk
WHERE da.demo_cnt > 10
ORDER BY ai.ib_income_band_sk, quantity_rank
LIMIT 100
