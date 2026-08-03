WITH
  joined AS (
    SELECT
      sr.sr_store_credit,
      sr.sr_return_ship_cost,
      sr.sr_return_quantity,
      sr.sr_return_amt,
      sr.sr_hdemo_sk,
      hd.hd_dep_count,
      hd.hd_vehicle_count,
      hd.hd_buy_potential,
      ARRAY[hd.hd_dep_count, hd.hd_vehicle_count] AS demo_counts_arr
    FROM store_returns sr
    JOIN household_demographics hd
      ON sr.sr_hdemo_sk = hd.hd_demo_sk
    WHERE sr.sr_store_credit > 20
      AND sr.sr_return_ship_cost BETWEEN 10 AND 500
      AND hd.hd_dep_count >= 3
      AND hd.hd_vehicle_count IS NOT NULL
      AND hd.hd_buy_potential <> 'Unknown'
  ),
  expanded AS (
    SELECT
      j.sr_store_credit,
      j.sr_return_ship_cost,
      j.sr_return_quantity,
      j.sr_return_amt,
      j.sr_hdemo_sk,
      j.hd_dep_count,
      j.hd_vehicle_count,
      j.hd_buy_potential,
      d.value AS demo_count_value
    FROM joined j
    CROSS JOIN UNNEST(j.demo_counts_arr) AS d(value)
  ),
  ranked AS (
    SELECT
      e.sr_store_credit,
      e.sr_return_ship_cost,
      e.sr_return_quantity,
      e.sr_return_amt,
      e.hd_dep_count,
      e.hd_vehicle_count,
      e.hd_buy_potential,
      e.sr_hdemo_sk,
      e.demo_count_value,
      CASE
        WHEN e.hd_buy_potential LIKE '%>10000%' THEN 'High'
        WHEN e.hd_buy_potential LIKE '%5001-10000%' THEN 'Medium'
        ELSE 'Low'
      END AS buy_potential_category,
      ROW_NUMBER() OVER (PARTITION BY e.hd_buy_potential ORDER BY e.sr_return_amt DESC) AS rn,
      RANK() OVER (ORDER BY e.sr_return_amt DESC) AS overall_rank
    FROM expanded e
    WHERE e.demo_count_value > 0
  ),
  anti AS (
    SELECT sr_hdemo_sk FROM store_returns WHERE sr_return_amt < 0
  ),
  intersect_keys AS (
    SELECT sr_hdemo_sk FROM store_returns WHERE sr_return_tax > 0
    INTERSECT
    SELECT hd_demo_sk FROM household_demographics WHERE hd_vehicle_count > 0
  ),
  union_set AS (
    SELECT sr_hdemo_sk FROM store_returns WHERE sr_store_credit > 100
    UNION
    SELECT hd_demo_sk FROM household_demographics WHERE hd_dep_count > 5
  )
SELECT
  r.sr_store_credit,
  r.sr_return_ship_cost,
  r.sr_return_quantity,
  r.sr_return_amt,
  r.hd_dep_count,
  r.hd_vehicle_count,
  r.buy_potential_category,
  r.demo_count_value,
  r.rn,
  r.overall_rank
FROM ranked r
WHERE r.sr_hdemo_sk NOT IN (SELECT sr_hdemo_sk FROM anti)
  AND r.sr_hdemo_sk IN (SELECT sr_hdemo_sk FROM intersect_keys)
  AND r.sr_hdemo_sk IN (SELECT sr_hdemo_sk FROM union_set)
ORDER BY r.overall_rank
LIMIT 100
