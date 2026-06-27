WITH sales_by_ship_mode AS (
    SELECT
        sm.sm_ship_mode_id,
        sm.sm_type,
        sm.sm_carrier,
        sum(cs.cs_ext_sales_price) AS total_sales,
        sum(cs.cs_net_profit) AS total_profit,
        avg(cs.cs_ext_discount_amt) AS avg_discount,
        count(DISTINCT cs.cs_order_number) AS distinct_orders,
        sum(cs.cs_quantity) AS total_quantity
    FROM catalog_sales cs
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE cs.cs_sold_date_sk BETWEEN 2451000 AND 2452000
      AND sm.sm_type = 'AIR'
    GROUP BY
        sm.sm_ship_mode_id,
        sm.sm_type,
        sm.sm_carrier
    HAVING sum(cs.cs_net_profit) > 0
)
SELECT
    sm_ship_mode_id,
    sm_type,
    sm_carrier,
    total_sales,
    total_profit,
    avg_discount,
    distinct_orders,
    total_quantity,
    rank() OVER (ORDER BY total_profit DESC) AS profit_rank,
    row_number() OVER (PARTITION BY sm_type ORDER BY total_sales DESC) AS sales_row_num
FROM sales_by_ship_mode
ORDER BY total_profit DESC
LIMIT 10
