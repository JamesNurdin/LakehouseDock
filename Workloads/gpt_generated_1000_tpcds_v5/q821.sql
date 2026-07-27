/*
  Goal: Identify the most profitable catalog pages (by department and page number) during business hours,
  filtering on high‑value sales, active TV promotions, and return reasons mentioning price.
  The query aggregates sales and returns, applies a HAVING filter on total paid amount,
  ranks pages within each department by profit, and provides an overall ranking.
*/
WITH sales_returns AS (
    SELECT
        cp.cp_department,
        cp.cp_catalog_page_number,
        td.t_hour,
        SUM(cs.cs_net_profit) AS total_profit,
        SUM(cr.cr_net_loss) AS total_return_loss,
        SUM(cs.cs_ext_sales_price) - SUM(cr.cr_return_amount) AS net_sales,
        COUNT(DISTINCT cs.cs_order_number) AS orders_cnt,
        SUM(cs.cs_quantity) AS total_quantity
    FROM catalog_sales cs
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
        AND cr.cr_item_sk = cs.cs_item_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE cs.cs_wholesale_cost > 50
      AND cs.cs_quantity >= 2
      AND p.p_channel_tv = 'N'
      AND r.r_reason_desc LIKE '%price%'
      AND td.t_hour BETWEEN 9 AND 17
    GROUP BY cp.cp_department, cp.cp_catalog_page_number, td.t_hour
    HAVING SUM(cs.cs_net_paid) > 5000
)
SELECT
    cp_department,
    cp_catalog_page_number,
    t_hour,
    total_profit,
    total_return_loss,
    net_sales,
    ROW_NUMBER() OVER (PARTITION BY cp_department ORDER BY total_profit DESC) AS profit_rank_within_dept,
    DENSE_RANK() OVER (ORDER BY total_profit DESC) AS overall_profit_rank
FROM sales_returns
ORDER BY total_profit DESC
LIMIT 100
