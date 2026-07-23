WITH sr_agg AS (
    SELECT
        sr.sr_item_sk,
        sr.sr_cdemo_sk,
        sr.sr_hdemo_sk,
        sr.sr_customer_sk,
        SUM(sr.sr_return_amt_inc_tax) AS total_return_inc_tax,
        COUNT(*) AS return_cnt,
        AVG(sr.sr_return_quantity) AS avg_return_qty,
        SUM(sr.sr_refunded_cash) AS total_refunded_cash
    FROM store_returns sr
    WHERE sr.sr_return_quantity > 0
      AND sr.sr_return_amt_inc_tax > 0
      AND sr.sr_return_time_sk BETWEEN 30000 AND 60000
    GROUP BY sr.sr_item_sk, sr.sr_cdemo_sk, sr.sr_hdemo_sk, sr.sr_customer_sk
    HAVING SUM(sr.sr_return_amt_inc_tax) > 5000
       AND COUNT(*) >= 3
)
SELECT
    i.i_brand,
    i.i_brand_id,
    i.i_units,
    cd.cd_gender,
    cd.cd_marital_status,
    c.c_birth_country,
    c.c_birth_year,
    hd.hd_vehicle_count,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    SUM(sr_agg.total_return_inc_tax) AS brand_income_total_return,
    SUM(sr_agg.return_cnt) AS brand_income_return_cnt,
    AVG(sr_agg.avg_return_qty) AS avg_return_qty,
    CASE
        WHEN SUM(sr_agg.total_return_inc_tax) > 20000 THEN 'HIGH'
        WHEN SUM(sr_agg.total_return_inc_tax) > 10000 THEN 'MEDIUM'
        ELSE 'LOW'
    END AS return_level,
    RANK() OVER (PARTITION BY ib.ib_lower_bound ORDER BY SUM(sr_agg.total_return_inc_tax) DESC) AS rank_in_income_band,
    ROW_NUMBER() OVER (PARTITION BY i.i_brand_id ORDER BY SUM(sr_agg.total_return_inc_tax) DESC) AS rownum_by_brand
FROM sr_agg
JOIN item i
    ON sr_agg.sr_item_sk = i.i_item_sk
JOIN customer c
    ON sr_agg.sr_customer_sk = c.c_customer_sk
JOIN customer_demographics cd
    ON sr_agg.sr_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd
    ON sr_agg.sr_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
WHERE i.i_units = 'Box'
  AND i.i_brand_id IN (7004003, 6008007)
  AND cd.cd_gender = 'F'
  AND c.c_birth_country = 'SWITZERLAND'
  AND c.c_birth_year BETWEEN 1960 AND 1990
  AND hd.hd_vehicle_count >= 2
  AND ib.ib_lower_bound >= 30000
GROUP BY
    i.i_brand,
    i.i_brand_id,
    i.i_units,
    cd.cd_gender,
    cd.cd_marital_status,
    c.c_birth_country,
    c.c_birth_year,
    hd.hd_vehicle_count,
    ib.ib_lower_bound,
    ib.ib_upper_bound
HAVING SUM(sr_agg.total_return_inc_tax) > 10000
ORDER BY brand_income_total_return DESC
LIMIT 100
