WITH filtered_returns AS (
    SELECT 
        cr_returning_hdemo_sk,
        cr_return_quantity,
        cr_net_loss,
        cr_reversed_charge,
        cr_return_amount
    FROM catalog_returns
    WHERE cr_reversed_charge > 20
      AND EXISTS (
          SELECT 1
          FROM catalog_returns cr2
          WHERE cr2.cr_returning_hdemo_sk = catalog_returns.cr_returning_hdemo_sk
            AND cr2.cr_return_amount > 100
      )
)
SELECT
    hd.hd_income_band_sk,
    hd.hd_buy_potential,
    regexp_extract(hd.hd_buy_potential, '(HIGH|MEDIUM)', 1) AS buy_level,
    COUNT(*) AS return_cnt,
    SUM(fr.cr_net_loss) AS total_net_loss,
    AVG(fr.cr_return_amount) AS avg_return_amount,
    CONCAT(hd.hd_buy_potential, '_', CAST(hd.hd_dep_count AS VARCHAR)) AS buy_dep_key
FROM filtered_returns fr
JOIN household_demographics hd
  ON fr.cr_returning_hdemo_sk = hd.hd_demo_sk
WHERE
    regexp_like(hd.hd_buy_potential, '^HIGH|MEDIUM')
    AND hd.hd_buy_potential LIKE 'HIGH%'
    AND hd.hd_vehicle_count >= 0
    AND SUBSTRING(hd.hd_buy_potential FROM 1 FOR 4) = 'HIGH'
GROUP BY
    hd.hd_income_band_sk,
    hd.hd_buy_potential,
    regexp_extract(hd.hd_buy_potential, '(HIGH|MEDIUM)', 1),
    CONCAT(hd.hd_buy_potential, '_', CAST(hd.hd_dep_count AS VARCHAR))
HAVING
    SUM(fr.cr_net_loss) > 0
ORDER BY total_net_loss DESC
LIMIT 100
