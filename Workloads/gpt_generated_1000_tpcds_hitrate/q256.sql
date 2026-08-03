WITH return_agg AS (
    SELECT
        sr_hdemo_sk,
        SUM(sr_return_amt) AS total_return_amt,
        SUM(sr_return_quantity) AS total_return_qty,
        COUNT(*) AS cnt_returns
    FROM store_returns
    WHERE sr_return_quantity > 1
      AND sr_return_amt > 10
      AND sr_return_tax >= 0
      AND sr_fee BETWEEN 0 AND 20
      AND sr_reversed_charge < 1000
      AND sr_store_credit >= 0
    GROUP BY sr_hdemo_sk
    HAVING SUM(sr_return_amt) > 100
),
category_dim AS (
    SELECT *
    FROM (VALUES
        (1, 'Low'),
        (2, 'Medium'),
        (3, 'High')
    ) AS t(cat_id, cat_name)
)
SELECT
    hd.hd_demo_sk,
    hd.hd_vehicle_count,
    hd.hd_dep_count,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    ra.total_return_amt,
    ra.total_return_qty,
    ss.ss_list_price,
    ss.ss_wholesale_cost,
    u.metric_value,
    u.metric_seq,
    ROW_NUMBER() OVER (PARTITION BY hd.hd_vehicle_count ORDER BY ra.total_return_amt DESC) AS vehicle_rank,
    CASE 
        WHEN ra.total_return_amt < 200 THEN cd.cat_name
        WHEN ra.total_return_amt < 500 THEN cd.cat_name
        ELSE cd.cat_name
    END AS return_category
FROM store_sales ss
JOIN household_demographics hd
    ON ss.ss_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN return_agg ra
    ON ra.sr_hdemo_sk = hd.hd_demo_sk
CROSS JOIN category_dim cd
CROSS JOIN UNNEST(ARRAY[ss.ss_quantity, ss.ss_ext_sales_price]) WITH ORDINALITY AS u(metric_value, metric_seq)
WHERE hd.hd_vehicle_count <= 3
  AND hd.hd_dep_count >= 2
  AND ss.ss_list_price BETWEEN 20 AND 80
  AND ss.ss_wholesale_cost < 50
  AND ib.ib_lower_bound >= 0
  AND ib.ib_upper_bound <= 20000
ORDER BY vehicle_rank, ra.total_return_amt DESC
LIMIT 100
