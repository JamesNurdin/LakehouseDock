WITH left_side AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_sold_time_sk,
        ss.ss_item_sk,
        ss.ss_quantity,
        ss.ss_wholesale_cost,
        ss.ss_net_profit,
        td.t_time_sk,
        td.t_hour,
        td.t_am_pm,
        td.t_meal_time,
        td.t_second
    FROM store_sales ss
    LEFT JOIN time_dim td
        ON ss.ss_sold_time_sk = td.t_time_sk
    WHERE
        ss.ss_quantity > 1
        AND ss.ss_wholesale_cost BETWEEN 10 AND 100
        AND td.t_hour IN (9, 12, 15)
        AND td.t_meal_time = 'Dinner'
        AND td.t_am_pm = 'PM'
),
left_with_lateral AS (
    SELECT
        ls.*, 
        cs_stats.avg_cs_ext_sales_price
    FROM left_side ls
    CROSS JOIN LATERAL (
        SELECT AVG(cs.cs_ext_sales_price) AS avg_cs_ext_sales_price
        FROM catalog_sales cs
        WHERE cs.cs_sold_time_sk = ls.t_time_sk
    ) AS cs_stats
),
first_union AS (
    SELECT
        COALESCE(ls.t_hour, cs_td.t_hour)               AS hour,
        COALESCE(ls.t_am_pm, cs_td.t_am_pm)           AS am_pm,
        COALESCE(ls.t_meal_time, cs_td.t_meal_time)   AS meal_time,
        ls.ss_item_sk                                 AS item_sk,
        cs.cs_item_sk                                 AS cs_item_sk,
        COALESCE(ls.ss_quantity, 0)                  AS quantity,
        COALESCE(ls.avg_cs_ext_sales_price, 0)       AS avg_cs_price,
        COALESCE(ls.ss_net_profit, 0) + COALESCE(cs.cs_net_profit, 0) AS total_net_profit,
        COALESCE(ls.t_second, cs_td.t_second)       AS t_second
    FROM left_with_lateral ls
    FULL OUTER JOIN catalog_sales cs
        ON cs.cs_sold_time_sk = ls.t_time_sk
    LEFT JOIN time_dim cs_td
        ON cs.cs_sold_time_sk = cs_td.t_time_sk
    WHERE
        (cs.cs_ext_ship_cost > 500 OR cs.cs_ext_ship_cost IS NULL)
        AND (cs.cs_wholesale_cost BETWEEN 20 AND 80 OR cs.cs_wholesale_cost IS NULL)
        AND (
            EXISTS (
                SELECT 1 FROM catalog_sales cs2
                WHERE cs2.cs_item_sk = cs.cs_item_sk
                  AND cs2.cs_ext_sales_price > 1000
            )
            OR cs.cs_item_sk IS NULL
        )
        AND (ls.t_second > 0 OR cs.cs_ext_ship_cost IS NOT NULL)
),
second_union AS (
    SELECT
        td.t_hour                              AS hour,
        td.t_am_pm                             AS am_pm,
        td.t_meal_time                         AS meal_time,
        NULL                                   AS item_sk,
        cs.cs_item_sk                          AS cs_item_sk,
        0                                      AS quantity,
        cs_lateral2.avg_cs_ext_sales_price2   AS avg_cs_price,
        cs.cs_net_profit                       AS total_net_profit,
        td.t_second
    FROM catalog_sales cs
    JOIN time_dim td
        ON cs.cs_sold_time_sk = td.t_time_sk
    CROSS JOIN LATERAL (
        SELECT AVG(cs3.cs_ext_sales_price) AS avg_cs_ext_sales_price2
        FROM catalog_sales cs3
        WHERE cs3.cs_sold_time_sk = td.t_time_sk
    ) AS cs_lateral2
    WHERE
        cs.cs_ext_ship_cost > 500
        AND cs.cs_wholesale_cost BETWEEN 20 AND 80
        AND cs.cs_ext_sales_price > 200
        AND td.t_hour IN (9, 12, 15)
        AND td.t_meal_time = 'Dinner'
        AND td.t_am_pm = 'PM'
),
unioned AS (
    SELECT * FROM first_union
    UNION
    SELECT * FROM second_union
)
SELECT
    hour,
    am_pm,
    meal_time,
    COUNT(DISTINCT COALESCE(item_sk, cs_item_sk)) AS distinct_items_sold,
    SUM(total_net_profit)                           AS sum_net_profit,
    AVG(avg_cs_price)                               AS avg_sales_price,
    MIN(t_second)                                   AS min_second,
    MAX(t_second)                                   AS max_second
FROM unioned
GROUP BY hour, am_pm, meal_time
ORDER BY sum_net_profit DESC
LIMIT 100
