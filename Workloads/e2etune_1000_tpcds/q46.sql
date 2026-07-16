WITH profit_by_page AS (
    SELECT cp.cp_catalog_page_id AS cp_id,
           d_sales.d_quarter_name AS quarter,
           SUM(cs.cs_net_profit) - COALESCE(SUM(cr.cr_net_loss), 0) AS net_profit
    FROM catalog_sales cs
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN date_dim d_sales ON cs.cs_sold_date_sk = d_sales.d_date_sk
    JOIN time_dim t_sold ON cs.cs_sold_time_sk = t_sold.t_time_sk
    LEFT JOIN catalog_returns cr ON cs.cs_order_number = cr.cr_order_number
                                 AND cs.cs_item_sk = cr.cr_item_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE cp.cp_type = 'monthly'
      AND p.p_discount_active = 'Y'
      AND t_sold.t_shift = 'Morning'
      AND d_sales.d_year BETWEEN 2001 AND 2003
    GROUP BY cp.cp_catalog_page_id, d_sales.d_quarter_name
    HAVING SUM(cs.cs_net_profit) > 1000
)
SELECT cp_id,
       quarter,
       net_profit,
       RANK() OVER (PARTITION BY quarter ORDER BY net_profit DESC) AS profit_rank
FROM profit_by_page
ORDER BY net_profit DESC
LIMIT 10
