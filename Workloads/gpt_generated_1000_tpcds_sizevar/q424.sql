WITH sampled_sales AS (
    SELECT *
    FROM catalog_sales TABLESAMPLE BERNOULLI (10)
),

agg_ship AS (
    SELECT
        sm.sm_ship_mode_id,
        sm.sm_type,
        sm.sm_code,
        cp.cp_catalog_page_sk,
        cp.cp_description,
        SUM(cs.cs_net_paid)               AS total_net_paid,
        SUM(cs.cs_net_profit)             AS total_net_profit,
        COUNT(*)                          AS sales_cnt,
        RANK() OVER (PARTITION BY sm.sm_type ORDER BY SUM(cs.cs_net_profit) DESC) AS profit_rank
    FROM sampled_sales cs
    RIGHT OUTER JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    INNER JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    INNER JOIN time_dim td
        ON cs.cs_sold_time_sk = td.t_time_sk
    WHERE
        sm.sm_code IN ('AIR', 'SEA')
        AND cp.cp_catalog_number IN (3, 14)
        AND td.t_sub_shift = 'morning'
        AND td.t_second BETWEEN 8 AND 16
        AND td.t_hour >= 8
    GROUP BY
        sm.sm_ship_mode_id,
        sm.sm_type,
        sm.sm_code,
        cp.cp_catalog_page_sk,
        cp.cp_description
    HAVING SUM(cs.cs_net_profit) > 1000
),

avg_profit_page AS (
    SELECT
        cs.cs_catalog_page_sk,
        AVG(cs.cs_net_profit) AS avg_page_profit
    FROM catalog_sales cs
    GROUP BY cs.cs_catalog_page_sk
),

ranked_sales AS (
    SELECT
        a.sm_ship_mode_id,
        a.sm_type,
        a.sm_code,
        a.cp_catalog_page_sk,
        a.cp_description,
        a.total_net_paid,
        a.total_net_profit,
        a.sales_cnt,
        a.profit_rank,
        CASE
            WHEN a.total_net_profit > COALESCE(p.avg_page_profit, 0) * 2 THEN 'HIGH'
            ELSE 'NORMAL'
        END AS profit_category,
        (SELECT AVG(cs_net_profit) FROM catalog_sales) AS overall_avg_profit
    FROM agg_ship a
    LEFT JOIN avg_profit_page p
        ON a.cp_catalog_page_sk = p.cs_catalog_page_sk
)

SELECT
    sm_ship_mode_id,
    sm_type,
    sm_code,
    cp_description,
    total_net_paid,
    total_net_profit,
    sales_cnt,
    profit_rank,
    profit_category,
    overall_avg_profit
FROM ranked_sales
WHERE profit_category = 'HIGH'
UNION
SELECT
    sm_ship_mode_id,
    sm_type,
    sm_code,
    cp_description,
    total_net_paid,
    total_net_profit,
    sales_cnt,
    profit_rank,
    profit_category,
    overall_avg_profit
FROM ranked_sales
WHERE profit_category = 'NORMAL' AND total_net_paid > 5000
ORDER BY total_net_profit DESC
LIMIT 100
