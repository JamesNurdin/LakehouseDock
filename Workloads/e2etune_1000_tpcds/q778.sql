WITH catalog_sales_agg AS (
    SELECT cp.cp_department,
           w.w_state,
           cp.cp_type,
           SUM(cs.cs_net_profit) AS total_sales_profit,
           COUNT(DISTINCT cs.cs_order_number) AS num_orders,
           SUM(cs.cs_quantity) AS total_quantity
    FROM catalog_sales cs
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    WHERE cp.cp_type = 'monthly'
      AND w.w_country = 'United States'
    GROUP BY cp.cp_department, w.w_state, cp.cp_type
), catalog_returns_agg AS (
    SELECT cp.cp_department,
           w.w_state,
           cp.cp_type,
           SUM(cr.cr_net_loss) AS total_return_loss,
           COUNT(*) AS num_returns
    FROM catalog_returns cr
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    WHERE cp.cp_type = 'monthly'
      AND w.w_country = 'United States'
    GROUP BY cp.cp_department, w.w_state, cp.cp_type
), combined AS (
    SELECT cs.cp_department AS department,
           cs.w_state AS state,
           cs.cp_type AS type,
           cs.total_sales_profit,
           COALESCE(cr.total_return_loss, 0) AS total_return_loss,
           cs.total_sales_profit - COALESCE(cr.total_return_loss, 0) AS net_profit,
           cs.num_orders,
           COALESCE(cr.num_returns, 0) AS num_returns,
           cs.total_quantity
    FROM catalog_sales_agg cs
    LEFT JOIN catalog_returns_agg cr
      ON cs.cp_department = cr.cp_department
     AND cs.w_state = cr.w_state
     AND cs.cp_type = cr.cp_type
)
SELECT department,
       state,
       type,
       net_profit,
       total_sales_profit,
       total_return_loss,
       num_orders,
       num_returns,
       total_quantity,
       CAST(net_profit / NULLIF(total_sales_profit, 0) AS DOUBLE) AS profit_margin,
       RANK() OVER (ORDER BY net_profit DESC) AS profit_rank
FROM combined
WHERE net_profit > 0
ORDER BY profit_rank
LIMIT 20
