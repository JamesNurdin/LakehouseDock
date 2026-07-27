WITH filtered_returns AS (
    SELECT *
    FROM web_returns wr
    WHERE wr.wr_returning_addr_sk IN (1581503, 541063)
      AND wr.wr_reversed_charge > 100
      AND EXISTS (
          SELECT 1
          FROM web_returns wr2
          WHERE wr2.wr_returning_addr_sk = wr.wr_returning_addr_sk
            AND wr2.wr_return_amt > 50
      )
)
SELECT
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    hd.hd_buy_potential,
    SUM(fr.wr_return_amt) AS total_return_amount,
    AVG(fr.wr_return_tax) AS avg_return_tax,
    COUNT(DISTINCT fr.wr_order_number) AS distinct_orders,
    MAX(fr.wr_return_quantity) AS max_quantity,
    (
        SELECT MAX(ib2.ib_upper_bound)
        FROM income_band ib2
        WHERE ib2.ib_lower_bound = ib.ib_lower_bound
    ) AS max_upper_for_lower
FROM filtered_returns fr
JOIN household_demographics hd
    ON fr.wr_refunded_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
WHERE hd.hd_dep_count <= 3
  AND ib.ib_upper_bound = 120000
GROUP BY ib.ib_lower_bound, ib.ib_upper_bound, hd.hd_buy_potential
ORDER BY total_return_amount DESC
LIMIT 100
