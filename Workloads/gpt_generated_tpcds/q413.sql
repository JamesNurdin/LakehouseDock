WITH aggregated_sales AS (
    SELECT
        wh.w_state,
        wh.w_city,
        SUM(cs.cs_quantity) AS total_quantity,
        SUM(cs.cs_net_paid) AS total_net_paid,
        SUM(cs.cs_net_profit) AS total_net_profit,
        AVG(cs.cs_ext_discount_amt) AS avg_discount_amount,
        AVG(cs.cs_ext_tax) AS avg_tax_amount,
        SUM(cs.cs_ext_sales_price) AS total_sales_price,
        SUM(cs.cs_ext_ship_cost) AS total_ship_cost,
        CASE
            WHEN SUM(cs.cs_net_paid) = 0 THEN 0
            ELSE SUM(cs.cs_net_profit) / SUM(cs.cs_net_paid)
        END AS profit_margin
    FROM catalog_sales cs
    JOIN warehouse wh
        ON cs.cs_warehouse_sk = wh.w_warehouse_sk
    WHERE cs.cs_quantity > 0
      AND cs.cs_net_profit > 0
    GROUP BY wh.w_state, wh.w_city
    HAVING SUM(cs.cs_net_profit) > 1000
)
SELECT
    w_state,
    w_city,
    total_quantity,
    total_net_paid,
    total_net_profit,
    avg_discount_amount,
    avg_tax_amount,
    total_sales_price,
    total_ship_cost,
    profit_margin,
    ROW_NUMBER() OVER (PARTITION BY w_state ORDER BY total_net_profit DESC) AS rank_within_state
FROM aggregated_sales
ORDER BY w_state, rank_within_state
LIMIT 20
