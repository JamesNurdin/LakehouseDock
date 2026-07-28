WITH sales_agg AS (
    SELECT
        i.i_class,
        i.i_brand,
        SUM(cs.cs_net_profit) AS total_profit,
        SUM(cs.cs_quantity) AS total_quantity,
        COUNT(DISTINCT cs.cs_order_number) AS order_cnt
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE cs.cs_ship_date_sk BETWEEN 2450825 AND 2450904
      AND cs.cs_ext_tax > 10
      AND i.i_units IN ('Case', 'Each')
      AND i.i_color <> ''
      AND cs.cs_wholesale_cost > 0
    GROUP BY ROLLUP (i.i_class, i.i_brand)
),
class_rank AS (
    SELECT
        i_class,
        i_brand,
        total_profit,
        total_quantity,
        order_cnt,
        AVG(total_profit) OVER (PARTITION BY i_class) AS avg_profit_in_class,
        RANK() OVER (ORDER BY total_profit DESC) AS profit_rank
    FROM sales_agg
    WHERE total_profit IS NOT NULL
)
SELECT
    i_class,
    i_brand,
    total_profit,
    total_quantity,
    order_cnt,
    avg_profit_in_class,
    profit_rank
FROM class_rank
WHERE profit_rank <= 10
ORDER BY i_class ASC, profit_rank
LIMIT 100
