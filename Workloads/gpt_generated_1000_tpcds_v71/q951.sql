WITH filtered_sales AS (
    SELECT
        ss.ss_store_sk,
        ss.ss_hdemo_sk,
        ss.ss_net_profit,
        ss.ss_ext_sales_price,
        ss.ss_coupon_amt,
        hd.hd_buy_potential,
        hd.hd_dep_count,
        s.s_state,
        s.s_city,
        s.s_hours,
        s.s_division_id,
        s.s_division_name
    FROM tpcds.store_sales ss
    JOIN tpcds.household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN tpcds.store s
        ON ss.ss_store_sk = s.s_store_sk
    WHERE hd.hd_buy_potential IN ('1001-5000', '>10000')
      AND hd.hd_dep_count >= 5
      AND s.s_state = 'CA'
      AND s.s_city = 'Los Angeles'
      AND s.s_hours = '8AM-12AM'
      AND ss.ss_ext_list_price > 1000
      AND ss.ss_coupon_amt < 500
      AND NOT EXISTS (
            SELECT 1
            FROM tpcds.store_sales ss2
            WHERE ss2.ss_store_sk = s.s_store_sk
              AND ss2.ss_coupon_amt > 3000
      )
),
store_agg AS (
    SELECT
        fs.ss_store_sk,
        fs.s_division_id,
        fs.s_division_name,
        SUM(fs.ss_net_profit) AS total_net_profit,
        SUM(fs.ss_ext_sales_price) AS total_sales,
        AVG(fs.ss_coupon_amt) AS avg_coupon_amt,
        ROW_NUMBER() OVER (PARTITION BY fs.s_division_id ORDER BY SUM(fs.ss_net_profit) DESC) AS rn_division
    FROM filtered_sales fs
    GROUP BY fs.ss_store_sk, fs.s_division_id, fs.s_division_name
),
division_agg AS (
    SELECT
        sa.s_division_id,
        sa.s_division_name,
        AVG(sa.total_net_profit) AS avg_total_profit,
        COUNT(*) AS store_count,
        SUM(sa.total_sales) AS sum_sales,
        RANK() OVER (ORDER BY AVG(sa.total_net_profit) DESC) AS division_rank
    FROM store_agg sa
    GROUP BY sa.s_division_id, sa.s_division_name
)
SELECT
    d.s_division_id,
    d.s_division_name,
    d.avg_total_profit,
    d.store_count,
    d.sum_sales,
    d.division_rank
FROM division_agg d
ORDER BY d.avg_total_profit DESC
LIMIT 100
