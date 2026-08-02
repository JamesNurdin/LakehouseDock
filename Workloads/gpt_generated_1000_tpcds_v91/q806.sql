WITH page_sales AS (
    SELECT
        cp.cp_catalog_page_sk,
        cp.cp_catalog_page_id,
        cp.cp_type,
        cp.cp_catalog_page_number,
        cp.cp_description,
        cs.cs_sold_time_sk,
        cs.cs_order_number,
        cs.cs_ext_wholesale_cost,
        cs.cs_ext_list_price,
        cs.cs_net_profit,
        ct.t_hour,
        ct.t_am_pm,
        cd.cd_marital_status,
        cd.cd_education_status
    FROM catalog_sales cs
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN time_dim ct ON cs.cs_sold_time_sk = ct.t_time_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    WHERE cs.cs_ext_wholesale_cost > 500
      AND cs.cs_ext_list_price BETWEEN 1000 AND 5000
      AND cp.cp_type = 'monthly'
      AND cd.cd_marital_status IN ('D', 'M')
      AND ct.t_hour BETWEEN 9 AND 17
)
SELECT
    ps.cp_catalog_page_id,
    ps.cp_catalog_page_number,
    ps.cp_type,
    ps.t_hour,
    ps.cd_marital_status,
    ps.cd_education_status,
    ps.cs_ext_wholesale_cost,
    ps.cs_ext_list_price,
    ps.cs_net_profit,
    CASE
        WHEN ps.cs_net_profit >= 2000 THEN 'High'
        WHEN ps.cs_net_profit >= 1000 THEN 'Medium'
        ELSE 'Low'
    END AS profit_category,
    ROW_NUMBER() OVER (PARTITION BY ps.cp_type ORDER BY ps.cs_net_profit DESC) AS profit_rank,
    AVG(ps.cs_net_profit) OVER (PARTITION BY ps.cp_type) AS avg_profit_type,
    SUM(ps.cs_net_profit) OVER (
        PARTITION BY ps.cp_type
        ORDER BY ps.cs_net_profit DESC
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_profit,
    w.word
FROM page_sales ps
CROSS JOIN UNNEST(split(ps.cp_description, ' ')) AS w(word)
WHERE EXISTS (
    SELECT 1
    FROM catalog_sales cs2
    WHERE cs2.cs_order_number = ps.cs_order_number
      AND cs2.cs_net_profit > ps.cs_net_profit
)
ORDER BY profit_rank
LIMIT 100
