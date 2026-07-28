WITH qualified_stores AS (
    SELECT DISTINCT
        s.s_store_sk,
        s.s_store_id,
        s.s_market_id,
        s.s_state
    FROM tpcds.store s
    WHERE s.s_market_id IN (2, 4, 8)
      AND s.s_state = 'CA'
      AND s.s_rec_start_date >= DATE '1999-01-01'
      AND s.s_rec_end_date <= DATE '2002-12-31'
),
sales_agg AS (
    SELECT
        qs.s_store_id,
        qs.s_market_id,
        qs.s_state,
        t.t_hour,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ss.ss_customer_sk) AS unique_customers,
        AVG(ss.ss_net_profit) AS avg_profit
    FROM qualified_stores qs
    JOIN tpcds.store_sales ss ON ss.ss_store_sk = qs.s_store_sk
    JOIN tpcds.time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN tpcds.household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    WHERE hd.hd_income_band_sk BETWEEN 7 AND 20
      AND hd.hd_vehicle_count >= 0
      AND t.t_hour BETWEEN 8 AND 18
    GROUP BY qs.s_store_id, qs.s_market_id, qs.s_state, t.t_hour
)
SELECT
    sa.s_market_id,
    AVG(sa.total_sales) AS avg_total_sales,
    SUM(sa.unique_customers) AS total_unique_customers,
    MAX(sa.avg_profit) AS max_avg_profit_per_store
FROM sales_agg sa
GROUP BY sa.s_market_id
HAVING AVG(sa.total_sales) > 10000
ORDER BY avg_total_sales DESC
LIMIT 100
