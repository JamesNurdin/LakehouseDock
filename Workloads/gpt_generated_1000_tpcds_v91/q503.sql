/* Goal: Compare aggregated sales metrics by household demographic segments across all sales (using a full outer join) and a subset of morning sales, then combine the two result sets. */
WITH cte_all AS (
    SELECT
        ss.ss_hdemo_sk AS hd_demo_sk,
        hd.hd_income_band_sk,
        hd.hd_dep_count,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS ticket_cnt,
        MIN(ss.ss_sales_price) AS min_sales_price,
        MAX(ss.ss_sales_price) AS max_sales_price,
        -- scalar subquery: average sales price for the same demographic segment
        (SELECT AVG(ss2.ss_ext_sales_price)
         FROM store_sales ss2
         WHERE ss2.ss_hdemo_sk = ss.ss_hdemo_sk) AS avg_sales_by_demo
    FROM store_sales ss
    FULL OUTER JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    -- filter using an IN subquery (uncorrelated)
    WHERE ss.ss_hdemo_sk IN (
        SELECT hd2.hd_demo_sk
        FROM household_demographics hd2
        WHERE hd2.hd_dep_count >= 5
    )
    GROUP BY ss.ss_hdemo_sk, hd.hd_income_band_sk, hd.hd_dep_count
),
cte_morning AS (
    SELECT
        ss.ss_hdemo_sk AS hd_demo_sk,
        hd.hd_income_band_sk,
        hd.hd_dep_count,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS ticket_cnt,
        MIN(ss.ss_sales_price) AS min_sales_price,
        MAX(ss.ss_sales_price) AS max_sales_price,
        (SELECT AVG(ss2.ss_ext_sales_price)
         FROM store_sales ss2
         WHERE ss2.ss_hdemo_sk = ss.ss_hdemo_sk) AS avg_sales_by_demo
    FROM store_sales ss
    JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN time_dim t
        ON ss.ss_sold_time_sk = t.t_time_sk
    WHERE t.t_sub_shift = 'morning'
      AND hd.hd_income_band_sk IN (
          SELECT DISTINCT hd3.hd_income_band_sk
          FROM household_demographics hd3
          WHERE hd3.hd_dep_count <= 3
      )
    GROUP BY ss.ss_hdemo_sk, hd.hd_income_band_sk, hd.hd_dep_count
)
SELECT
    hd_demo_sk,
    hd_income_band_sk,
    hd_dep_count,
    total_sales,
    ticket_cnt,
    min_sales_price,
    max_sales_price,
    avg_sales_by_demo,
    'full_all' AS source_type
FROM cte_all
UNION ALL
SELECT
    hd_demo_sk,
    hd_income_band_sk,
    hd_dep_count,
    total_sales,
    ticket_cnt,
    min_sales_price,
    max_sales_price,
    avg_sales_by_demo,
    'morning' AS source_type
FROM cte_morning
ORDER BY total_sales DESC, hd_demo_sk
LIMIT 100
