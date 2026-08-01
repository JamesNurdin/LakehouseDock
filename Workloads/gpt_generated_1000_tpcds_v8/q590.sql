WITH
    demo_filtered AS (
        SELECT
            hd_demo_sk,
            hd_income_band_sk,
            hd_buy_potential,
            regexp_extract(hd_buy_potential, '(\\d+)-(\\d+)', 1) AS low_range,
            regexp_extract(hd_buy_potential, '(\\d+)-(\\d+)', 2) AS high_range
        FROM household_demographics
        WHERE regexp_like(hd_buy_potential, '^\\d+-\\d+$')
          AND hd_buy_potential LIKE '%-%'
    ),
    income_joined AS (
        SELECT
            d.hd_demo_sk,
            d.hd_buy_potential,
            i.ib_lower_bound,
            i.ib_upper_bound,
            CASE
                WHEN i.ib_upper_bound IS NULL THEN 'No Upper'
                ELSE concat(CAST(i.ib_lower_bound AS VARCHAR), '-', CAST(i.ib_upper_bound AS VARCHAR))
            END AS income_range
        FROM demo_filtered d
        JOIN income_band i
          ON d.hd_income_band_sk = i.ib_income_band_sk
    ),
    sales_demo AS (
        SELECT
            ss.ss_hdemo_sk,
            ss.ss_quantity,
            ss.ss_ext_sales_price,
            ss.ss_net_profit,
            CASE
                WHEN ss.ss_net_profit > 0 THEN 'Profitable'
                ELSE 'Loss'
            END AS profit_flag
        FROM store_sales ss
        WHERE ss.ss_ext_sales_price > 0
    ),
    full_joined AS (
        SELECT
            COALESCE(sd.ss_hdemo_sk, ij.hd_demo_sk) AS demo_key,
            ij.hd_buy_potential,
            ij.income_range,
            sd.ss_quantity,
            sd.ss_ext_sales_price,
            sd.profit_flag
        FROM income_joined ij
        FULL OUTER JOIN sales_demo sd
          ON ij.hd_demo_sk = sd.ss_hdemo_sk
    ),
    intersect_keys AS (
        SELECT hd_demo_sk FROM household_demographics WHERE hd_buy_potential LIKE '5%'
        INTERSECT
        SELECT ss_hdemo_sk FROM store_sales WHERE ss_ext_sales_price > 5000
    ),
    except_keys AS (
        SELECT hd_demo_sk FROM household_demographics WHERE hd_vehicle_count > 0
        EXCEPT
        SELECT ss_hdemo_sk FROM store_sales WHERE ss_quantity = 0
    ),
    union_agg AS (
        SELECT demo_key, SUM(ss_ext_sales_price) AS total_sales
        FROM full_joined
        GROUP BY demo_key
        UNION ALL
        SELECT demo_key, SUM(ss_ext_sales_price) * 1.1 AS total_sales
        FROM full_joined
        GROUP BY demo_key
    )
SELECT
    u.demo_key,
    i.hd_buy_potential,
    SUM(u.total_sales) AS agg_total_sales,
    CASE
        WHEN COUNT(*) FILTER (WHERE i.hd_buy_potential IS NOT NULL) > 0 THEN 'Has Demo'
        ELSE 'No Demo'
    END AS demo_presence
FROM union_agg u
LEFT JOIN income_joined i
  ON u.demo_key = i.hd_demo_sk
WHERE u.demo_key NOT IN (
        SELECT hd_demo_sk FROM household_demographics WHERE hd_dep_count = 0
    )
  AND u.demo_key IN (SELECT hd_demo_sk FROM intersect_keys)
  AND u.demo_key NOT IN (SELECT hd_demo_sk FROM except_keys)
GROUP BY ROLLUP(u.demo_key, i.hd_buy_potential)
HAVING SUM(u.total_sales) > 1000
ORDER BY agg_total_sales DESC
LIMIT 100
