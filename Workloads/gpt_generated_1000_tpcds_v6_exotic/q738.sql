WITH store_income_agg AS (
    SELECT
        ss.ss_store_sk,
        hd.hd_income_band_sk,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit,
        COUNT(*) AS txn_count
    FROM store_sales ss
    JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    WHERE hd.hd_dep_count >= 2
      AND hd.hd_vehicle_count <= 3
      AND hd.hd_buy_potential LIKE '1001-5000%'
      AND ss.ss_list_price > 10
      AND ss.ss_sold_time_sk BETWEEN 30000 AND 65000
    GROUP BY ss.ss_store_sk, hd.hd_income_band_sk
),
store_total AS (
    SELECT
        si.ss_store_sk,
        AVG(si.total_sales) AS avg_sales_per_income_band,
        SUM(si.total_profit) AS store_total_profit,
        COUNT(DISTINCT si.hd_income_band_sk) AS income_band_cnt
    FROM store_income_agg si
    GROUP BY si.ss_store_sk
    HAVING SUM(si.total_profit) > (
        SELECT AVG(ss2.ss_net_profit)
        FROM store_sales ss2
        WHERE ss2.ss_list_price > 20
    )
)
SELECT
    st.ss_store_sk,
    s.s_store_name,
    st.avg_sales_per_income_band,
    st.store_total_profit,
    st.income_band_cnt,
    RANK() OVER (ORDER BY st.store_total_profit DESC) AS profit_rank,
    CASE
        WHEN EXISTS (
            SELECT 1
            FROM store_sales ss3
            WHERE ss3.ss_store_sk = st.ss_store_sk
              AND ss3.ss_list_price > 100
        ) THEN 'HighPriceExists'
        ELSE 'NoHighPrice'
    END AS high_price_flag
FROM store_total st
LEFT JOIN store s
    ON st.ss_store_sk = s.s_store_sk
WHERE s.s_state = 'CA'
  AND s.s_gmt_offset BETWEEN -8.00 AND -5.00
  AND s.s_tax_percentage < 8.00
  AND s.s_city IS NOT NULL
  AND s.s_zip LIKE '9%'
ORDER BY st.store_total_profit DESC
LIMIT 100
