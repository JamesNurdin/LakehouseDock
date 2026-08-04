WITH sales_agg AS (
    SELECT
        s.s_store_sk,
        s.s_store_name,
        td.t_hour,
        td.t_meal_time,
        SUM(ss.ss_net_paid) AS total_sales,
        SUM(ss.ss_ext_discount_amt) AS total_discount,
        COUNT(*) AS sales_cnt
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    WHERE s.s_geography_class = 'Unknown'
      AND s.s_company_id = 1
      AND s.s_number_employees BETWEEN 200 AND 300
      AND td.t_meal_time = 'dinner'
      AND td.t_hour >= 12
    GROUP BY s.s_store_sk, s.s_store_name, td.t_hour, td.t_meal_time
),

returns_agg AS (
    SELECT
        s.s_store_sk,
        td.t_hour,
        td.t_meal_time,
        SUM(sr.sr_net_loss) AS total_loss,
        COUNT(*) AS returns_cnt,
        SUM(sr.sr_return_tax) AS total_return_tax
    FROM store_returns sr
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN time_dim td ON sr.sr_return_time_sk = td.t_time_sk
    WHERE sr.sr_return_tax > 2.0
      AND sr.sr_reversed_charge < 100
      AND sr.sr_store_credit BETWEEN 10 AND 2000
      AND s.s_number_employees > 210
      AND s.s_geography_class = 'Unknown'
    GROUP BY s.s_store_sk, td.t_hour, td.t_meal_time
),

full_combined AS (
    SELECT
        COALESCE(sa.s_store_sk, ra.s_store_sk) AS store_sk,
        COALESCE(sa.s_store_name, s2.s_store_name) AS store_name,
        COALESCE(sa.t_hour, ra.t_hour) AS hour,
        COALESCE(sa.t_meal_time, ra.t_meal_time) AS meal_time,
        sa.total_sales,
        ra.total_loss,
        sa.sales_cnt,
        ra.returns_cnt,
        CASE
            WHEN COALESCE(sa.total_sales, 0) > 10000 THEN 'High'
            ELSE 'Low'
        END AS sales_category
    FROM sales_agg sa
    FULL OUTER JOIN returns_agg ra
        ON sa.s_store_sk = ra.s_store_sk
       AND sa.t_hour = ra.t_hour
       AND sa.t_meal_time = ra.t_meal_time
    LEFT JOIN store s2 ON COALESCE(sa.s_store_sk, ra.s_store_sk) = s2.s_store_sk
)

SELECT
    fc.store_name,
    fc.hour,
    fc.meal_time,
    fc.sales_category,
    fc.total_sales,
    fc.total_loss,
    fc.sales_cnt,
    fc.returns_cnt,
    CASE
        WHEN fc.total_sales IS NULL THEN 'NoSales'
        WHEN fc.total_loss IS NULL THEN 'NoReturns'
        ELSE 'Both'
    END AS presence_flag,
    (SELECT MAX(total_sales) FROM sales_agg) AS max_sales_overall,
    flag.threshold
FROM full_combined fc
CROSS JOIN (
    SELECT 1 AS threshold UNION ALL SELECT 2 AS threshold
) AS flag
WHERE EXISTS (
    SELECT 1
    FROM store_returns sr2
    WHERE sr2.sr_store_sk = fc.store_sk
      AND sr2.sr_return_tax > 5
)
ORDER BY fc.total_sales DESC NULLS LAST, fc.store_name
LIMIT 100
