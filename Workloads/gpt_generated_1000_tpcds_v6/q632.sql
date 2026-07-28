WITH sales_with_time AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_sold_time_sk,
        ss.ss_item_sk,
        ss.ss_store_sk,
        ss.ss_ext_list_price,
        ss.ss_wholesale_cost,
        ss.ss_net_paid,
        ss.ss_net_profit,
        ss.ss_ext_discount_amt,
        t.t_meal_time,
        t.t_second
    FROM store_sales ss
    LEFT JOIN time_dim t
        ON ss.ss_sold_time_sk = t.t_time_sk
    WHERE ss.ss_ext_list_price > 1000
      AND ss.ss_wholesale_cost < 50
      AND t.t_meal_time = 'lunch'
),

profit_categories AS (
    SELECT
        'HIGH' AS profit_category,
        ss.ss_store_sk,
        ss.ss_net_profit
    FROM store_sales ss
    WHERE ss.ss_net_profit > 500
    UNION ALL
    SELECT
        'LOW' AS profit_category,
        ss.ss_store_sk,
        ss.ss_net_profit
    FROM store_sales ss
    WHERE ss.ss_net_profit <= 500
),

final AS (
    SELECT
        s.t_meal_time,
        s.t_second,
        COUNT(*) AS sales_count,
        SUM(s.ss_net_paid) AS total_net_paid,
        AVG(s.ss_ext_discount_amt) AS avg_discount,
        MAX(s.ss_net_profit) AS max_profit,
        CASE
            WHEN MAX(s.ss_net_profit) > 1000 THEN 'Very High'
            WHEN MAX(s.ss_net_profit) > 500 THEN 'High'
            ELSE 'Normal'
        END AS profit_level,
        ROW_NUMBER() OVER (PARTITION BY s.t_meal_time ORDER BY SUM(s.ss_net_paid) DESC) AS rn,
        (SELECT AVG(ss_ext_discount_amt) FROM store_sales) AS overall_avg_discount,
        EXISTS (
            SELECT 1
            FROM profit_categories pc
            WHERE pc.profit_category = 'HIGH'
        ) AS any_high_profit_store
    FROM sales_with_time s
    GROUP BY s.t_meal_time, s.t_second
)

SELECT
    t_meal_time,
    t_second,
    sales_count,
    total_net_paid,
    avg_discount,
    max_profit,
    profit_level,
    rn,
    overall_avg_discount,
    any_high_profit_store
FROM final
WHERE rn <= 5
ORDER BY total_net_paid DESC
