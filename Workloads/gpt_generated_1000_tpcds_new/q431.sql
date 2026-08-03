WITH sampled_sales AS (
    SELECT *
    FROM store_sales
    TABLESAMPLE BERNOULLI (10)  -- sample 10% of rows
),
base AS (
    SELECT
        s.s_store_name,
        hd.hd_buy_potential,
        td.t_meal_time,
        hd.hd_dep_count,
        ss.ss_net_paid,
        ss.ss_ticket_number,
        (
            SELECT SUM(r2.sr_refunded_cash)
            FROM store_returns r2
            WHERE r2.sr_store_sk = s.s_store_sk
        ) AS total_refunded_cash
    FROM sampled_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    WHERE td.t_meal_time = 'dinner'
      AND td.t_hour BETWEEN 17 AND 20
      AND hd.hd_income_band_sk IN (3, 7, 13)
      AND s.s_state = 'CA'
      AND ss.ss_quantity > 1
      AND ss.ss_net_paid > 50
      AND NOT EXISTS (
          SELECT 1
          FROM store_returns r2
          WHERE r2.sr_store_sk = s.s_store_sk
            AND r2.sr_return_tax > 20
      )
),
aggregated AS (
    SELECT
        s_store_name,
        hd_buy_potential,
        t_meal_time,
        hd_dep_count,
        total_refunded_cash,
        SUM(ss_net_paid) AS total_sales,
        AVG(ss_net_paid) AS avg_sales,
        COUNT(DISTINCT ss_ticket_number) AS order_cnt,
        MIN(ss_net_paid) AS min_sale,
        MAX(ss_net_paid) AS max_sale,
        CASE WHEN hd_dep_count >= 5 THEN 'Large' ELSE 'Small' END AS household_size_category
    FROM base
    GROUP BY s_store_name, hd_buy_potential, t_meal_time, hd_dep_count, total_refunded_cash
    HAVING SUM(ss_net_paid) > 1000
       AND COUNT(DISTINCT ss_ticket_number) > 5
)
SELECT
    s_store_name,
    hd_buy_potential,
    t_meal_time,
    household_size_category,
    total_sales,
    avg_sales,
    order_cnt,
    min_sale,
    max_sale,
    total_refunded_cash
FROM (
    SELECT
        *,
        ROW_NUMBER() OVER (PARTITION BY s_store_name ORDER BY total_sales DESC) AS rn
    FROM aggregated
) final
WHERE rn <= 3
ORDER BY total_sales DESC
OFFSET 0 LIMIT 100
