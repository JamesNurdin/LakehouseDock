WITH filtered_sales AS (
    SELECT
        ss.ss_hdemo_sk,
        hd.hd_demo_sk,
        hd.hd_income_band_sk,
        hd.hd_buy_potential,
        hd.hd_vehicle_count,
        hd.hd_dep_count,
        ss.ss_ext_sales_price,
        ss.ss_quantity,
        ss.ss_sales_price,
        ss.ss_ext_discount_amt,
        ss.ss_ticket_number
    FROM store_sales ss
    INNER JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    WHERE hd.hd_vehicle_count BETWEEN 0 AND 5
      AND hd.hd_dep_count >= 0
      AND hd.hd_buy_potential LIKE '0-%'
      AND ss.ss_ext_sales_price > 100
      AND ss.ss_quantity BETWEEN 1 AND 20
      AND ss.ss_ext_discount_amt < 500
      AND EXISTS (
          SELECT 1
          FROM income_band ib
          WHERE ib.ib_income_band_sk = hd.hd_income_band_sk
            AND ib.ib_lower_bound >= 50000
            AND ib.ib_upper_bound <= 200000
      )
),
agg_sales AS (
    SELECT
        hd_buy_potential,
        hd_income_band_sk,
        hd_demo_sk,
        SUM(ss_ext_sales_price) AS total_sales,
        SUM(ss_quantity) AS total_quantity,
        AVG(ss_sales_price) AS avg_sales_price,
        COUNT(DISTINCT ss_ticket_number) AS distinct_tickets
    FROM filtered_sales
    GROUP BY hd_buy_potential, hd_income_band_sk, hd_demo_sk
),
union_sales AS (
    SELECT
        hd_buy_potential,
        hd_income_band_sk,
        hd_demo_sk,
        total_sales,
        total_quantity,
        avg_sales_price,
        distinct_tickets
    FROM agg_sales
    WHERE total_sales > 5000
    UNION ALL
    SELECT
        hd_buy_potential,
        hd_income_band_sk,
        hd_demo_sk,
        total_sales,
        total_quantity,
        avg_sales_price,
        distinct_tickets
    FROM agg_sales
    WHERE total_quantity > 1000
)
SELECT
    u.hd_buy_potential,
    u.hd_income_band_sk,
    (SELECT ib.ib_lower_bound FROM income_band ib WHERE ib.ib_income_band_sk = u.hd_income_band_sk) AS ib_lower_bound,
    (SELECT ib.ib_upper_bound FROM income_band ib WHERE ib.ib_income_band_sk = u.hd_income_band_sk) AS ib_upper_bound,
    u.total_sales,
    u.total_quantity,
    u.avg_sales_price,
    u.distinct_tickets
FROM union_sales u
WHERE NOT EXISTS (
    SELECT 1
    FROM store_sales ss_ex
    WHERE ss_ex.ss_hdemo_sk = u.hd_demo_sk
      AND ss_ex.ss_ext_discount_amt > 1000
)
ORDER BY u.total_sales DESC
LIMIT 100
