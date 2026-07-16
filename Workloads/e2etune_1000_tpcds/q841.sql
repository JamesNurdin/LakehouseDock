WITH store_income_stats AS (
    SELECT
        s.s_store_id,
        s.s_state,
        hd.hd_income_band_sk AS hd_income_band_sk,
        COUNT(DISTINCT ss.ss_customer_sk) AS distinct_customers,
        SUM(ss.ss_net_paid) AS total_net_paid,
        AVG(ss.ss_net_profit) AS avg_net_profit,
        SUM(ss.ss_ext_discount_amt) AS total_discount
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    WHERE
        hd.hd_vehicle_count >= 2
        AND hd.hd_buy_potential IN ('1001-5000', '5001-10000')
        AND s.s_tax_percentage > 0.07
        AND ss.ss_sold_date_sk BETWEEN 2451545 AND 2451910
    GROUP BY
        s.s_store_id,
        s.s_state,
        hd.hd_income_band_sk
    HAVING
        SUM(ss.ss_net_paid) > 10000
)
SELECT
    s_store_id,
    s_state,
    hd_income_band_sk,
    distinct_customers,
    total_net_paid,
    avg_net_profit,
    total_discount,
    RANK() OVER (PARTITION BY s_state ORDER BY total_net_paid DESC) AS sales_rank_state
FROM store_income_stats
ORDER BY s_state, sales_rank_state
