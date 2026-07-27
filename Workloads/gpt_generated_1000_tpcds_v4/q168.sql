WITH sales_agg AS (
    SELECT
        cs_bill_hdemo_sk,
        SUM(cs_ext_sales_price) AS total_sales,
        SUM(cs_ext_tax) AS total_tax,
        AVG(cs_net_profit) AS avg_profit,
        COUNT(*) AS order_cnt
    FROM tpcds.catalog_sales
    WHERE cs_ext_tax > 20.00
    GROUP BY cs_bill_hdemo_sk
),
hd_filtered AS (
    SELECT
        hd_demo_sk,
        hd_income_band_sk,
        hd_vehicle_count,
        hd_dep_count
    FROM tpcds.household_demographics
    WHERE hd_vehicle_count >= 1
      AND hd_dep_count <= 5
      AND hd_income_band_sk IN (
          SELECT ib_income_band_sk
          FROM tpcds.income_band
          WHERE ib_upper_bound >= 80000
      )
),
joined AS (
    SELECT
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        s.total_sales,
        s.total_tax,
        s.avg_profit,
        s.order_cnt
    FROM sales_agg s
    JOIN hd_filtered h
        ON s.cs_bill_hdemo_sk = h.hd_demo_sk
    JOIN tpcds.income_band ib
        ON h.hd_income_band_sk = ib.ib_income_band_sk
    WHERE ib.ib_lower_bound > 60000
)
SELECT
    joined.ib_income_band_sk,
    joined.ib_lower_bound,
    joined.ib_upper_bound,
    SUM(joined.total_sales) AS band_total_sales,
    AVG(joined.avg_profit) AS band_avg_profit,
    SUM(joined.total_tax) AS band_total_tax,
    COUNT(*) AS num_households
FROM joined
WHERE joined.total_sales > (
    SELECT 0.01 * SUM(cs_ext_sales_price)
    FROM tpcds.catalog_sales
)
GROUP BY joined.ib_income_band_sk, joined.ib_lower_bound, joined.ib_upper_bound
HAVING SUM(joined.total_sales) > 50000
   AND AVG(joined.avg_profit) > 0
ORDER BY band_total_sales DESC
LIMIT 100
