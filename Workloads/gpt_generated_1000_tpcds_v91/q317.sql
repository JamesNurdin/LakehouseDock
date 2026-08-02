WITH filtered_wr AS (
    SELECT *
    FROM web_returns wr
    WHERE wr.wr_fee > 20.00
      AND wr.wr_return_quantity > 1
)
SELECT
    cd.cd_gender,
    cd.cd_marital_status,
    CASE WHEN cd.cd_credit_rating = 'Good' THEN 'Preferred' ELSE 'Other' END AS credit_category,
    t.charge_type,
    SUM(wr.wr_return_amt_inc_tax) AS total_return_amount,
    AVG(wr.wr_fee) AS avg_fee,
    COUNT(DISTINCT wr.wr_item_sk) AS distinct_items,
    SUM(t.charge_amount) AS total_charge_amount,
    MIN(wr.wr_return_quantity) AS min_quantity,
    MAX(wr.wr_return_quantity) AS max_quantity
FROM filtered_wr wr
JOIN customer_demographics cd
    ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
CROSS JOIN UNNEST(
    map(
        ARRAY['fee', 'reversed_charge'],
        ARRAY[wr.wr_fee, wr.wr_reversed_charge]
    )
) AS t(charge_type, charge_amount)
WHERE cd.cd_credit_rating = 'Good'
  AND cd.cd_dep_employed_count >= 2
  AND EXISTS (
      SELECT 1
      FROM web_returns wr2
      JOIN customer_demographics cd2
          ON wr2.wr_returning_cdemo_sk = cd2.cd_demo_sk
      WHERE wr2.wr_return_quantity > 5
        AND cd2.cd_credit_rating = 'High Risk'
        AND wr2.wr_refunded_cdemo_sk = wr.wr_refunded_cdemo_sk
  )
GROUP BY
    cd.cd_gender,
    cd.cd_marital_status,
    CASE WHEN cd.cd_credit_rating = 'Good' THEN 'Preferred' ELSE 'Other' END,
    t.charge_type
ORDER BY total_return_amount DESC
LIMIT 100
