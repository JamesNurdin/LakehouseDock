WITH
  -- Customers who bought a lot, minus those who bought very few
  except_keys AS (
    SELECT ss_customer_sk
    FROM store_sales
    WHERE ss_quantity > 5
    EXCEPT
    SELECT ss_customer_sk
    FROM store_sales
    WHERE ss_quantity < 2
  ),
  -- Customers who bought expensive items and also made good profit
  intersect_keys AS (
    SELECT ss_customer_sk
    FROM store_sales
    WHERE ss_sales_price > 100
    INTERSECT
    SELECT ss_customer_sk
    FROM store_sales
    WHERE ss_net_profit > 10
  ),
  -- Aggregated sales by buying potential and hour of day
  agg AS (
    SELECT
      hd.hd_buy_potential,
      td.t_hour,
      SUM(ss.ss_ext_sales_price)       AS total_sales,
      AVG(ss.ss_net_profit)           AS avg_profit,
      COUNT(*)                         AS sales_cnt,
      MIN(ss.ss_ext_sales_price)      AS min_sales,
      MAX(ss.ss_ext_sales_price)      AS max_sales
    FROM store_sales ss
    LEFT OUTER JOIN household_demographics hd
      ON ss.ss_hdemo_sk = hd.hd_demo_sk
    -- Lateral join to fetch the time attributes for the sold time key
    CROSS JOIN LATERAL (
      SELECT t_hour, t_minute
      FROM time_dim td
      WHERE td.t_time_sk = ss.ss_sold_time_sk
    ) td
    LEFT OUTER JOIN income_band ib
      ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE
      hd.hd_dep_count >= 2                           -- at least 2 dependents
      AND ib.ib_upper_bound <= 120000                -- upper income bound filter
      AND td.t_hour BETWEEN 8 AND 17                 -- business hours
      AND ss.ss_ext_sales_price > (
        SELECT MAX(ss2.ss_ext_sales_price)
        FROM store_sales ss2
        WHERE ss2.ss_quantity = 1
      )                                             -- compare to scalar sub‑query
      AND NOT EXISTS (
        SELECT 1
        FROM household_demographics hd2
        WHERE hd2.hd_demo_sk = ss.ss_hdemo_sk
          AND hd2.hd_vehicle_count = 0           -- exclude households with no vehicle
      )
      AND ss.ss_customer_sk IN (SELECT ss_customer_sk FROM except_keys)
      AND ss.ss_customer_sk IN (SELECT ss_customer_sk FROM intersect_keys)
    GROUP BY ROLLUP (hd.hd_buy_potential, td.t_hour)
  )
SELECT
  hd_buy_potential,
  t_hour,
  total_sales,
  avg_profit,
  sales_cnt,
  min_sales,
  max_sales
FROM agg
ORDER BY total_sales DESC
LIMIT 100
