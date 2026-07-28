/*
  Goal: Analyze total sales, profit, and return performance by warehouse, product category and carrier for high‑value orders, flag items with above‑average profit and rank warehouses by profit.
*/
WITH overall_avg AS (
    SELECT AVG(cs2.cs_net_profit) AS avg_profit
    FROM catalog_sales cs2
    WHERE cs2.cs_wholesale_cost > 30.00
)
SELECT
    w.w_warehouse_name,
    i.i_category,
    sm.sm_carrier,
    SUM(cs.cs_net_paid_inc_tax)            AS total_sales_inc_tax,
    SUM(cs.cs_net_profit)                  AS total_profit,
    AVG(cs.cs_net_profit)                  AS avg_profit,
    COUNT(*)                               AS order_count,
    SUM(CASE WHEN cs.cs_net_profit > overall_avg.avg_profit THEN 1 ELSE 0 END) AS above_avg_profit_orders,
    SUM(wr.wr_return_quantity)             AS total_return_qty,
    RANK() OVER (ORDER BY SUM(cs.cs_net_profit) DESC) AS profit_rank
FROM catalog_sales cs
JOIN customer_demographics cd
    ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
JOIN item i
    ON cs.cs_item_sk = i.i_item_sk
JOIN ship_mode sm
    ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w
    ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN web_returns wr
    ON wr.wr_item_sk = i.i_item_sk
CROSS JOIN overall_avg
WHERE cs.cs_wholesale_cost > 30.00
  AND cs.cs_net_paid_inc_tax >= 1000.00
  AND sm.sm_carrier = 'FEDEX'
  AND sm.sm_contract = 'YvxVaJI10'
  AND cd.cd_gender = 'M'
GROUP BY
    w.w_warehouse_name,
    i.i_category,
    sm.sm_carrier,
    overall_avg.avg_profit
ORDER BY total_profit DESC
LIMIT 100
