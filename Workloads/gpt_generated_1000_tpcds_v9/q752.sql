WITH catalog_agg AS (
  SELECT
    i_sales.i_category AS category,
    td_sold.t_hour AS hour_of_day,
    cc_sales.cc_market_manager AS market_manager,
    CAST(NULL AS varchar) AS page_type,
    SUM(cs.cs_net_profit) AS total_net_profit,
    SUM(cs.cs_ext_sales_price) AS total_sales,
    SUM(cr.cr_return_quantity) AS total_return_qty,
    SUM(cr.cr_net_loss) AS total_return_loss,
    CASE
      WHEN SUM(cs.cs_net_profit) - COALESCE(SUM(cr.cr_net_loss), 0) > 0 THEN 'Profit'
      ELSE 'Loss'
    END AS profit_flag
  FROM catalog_sales cs
  JOIN time_dim td_sold
    ON cs.cs_sold_time_sk = td_sold.t_time_sk
  JOIN call_center cc_sales
    ON cs.cs_call_center_sk = cc_sales.cc_call_center_sk
  JOIN catalog_page cp_sales
    ON cs.cs_catalog_page_sk = cp_sales.cp_catalog_page_sk
  JOIN warehouse w_sales
    ON cs.cs_warehouse_sk = w_sales.w_warehouse_sk
  JOIN item i_sales
    ON cs.cs_item_sk = i_sales.i_item_sk
  JOIN promotion p
    ON cs.cs_promo_sk = p.p_promo_sk
       AND p.p_item_sk = i_sales.i_item_sk
  LEFT JOIN catalog_returns cr
    ON cs.cs_order_number = cr.cr_order_number
       AND cs.cs_item_sk = cr.cr_item_sk
  LEFT JOIN time_dim td_ret
    ON cr.cr_returned_time_sk = td_ret.t_time_sk
  LEFT JOIN call_center cc_return
    ON cr.cr_call_center_sk = cc_return.cc_call_center_sk
  LEFT JOIN catalog_page cp_return
    ON cr.cr_catalog_page_sk = cp_return.cp_catalog_page_sk
  LEFT JOIN warehouse w_return
    ON cr.cr_warehouse_sk = w_return.w_warehouse_sk
  LEFT JOIN item i_return
    ON cr.cr_item_sk = i_return.i_item_sk
  LEFT JOIN inventory inv
    ON cs.cs_item_sk = inv.inv_item_sk
  LEFT JOIN warehouse w_inv
    ON inv.inv_warehouse_sk = w_inv.w_warehouse_sk
  WHERE cc_sales.cc_rec_start_date <= DATE '2002-01-01'
    AND i_sales.i_rec_end_date >= DATE '2002-01-01'
  GROUP BY
    i_sales.i_category,
    td_sold.t_hour,
    cc_sales.cc_market_manager
),

web_agg AS (
  SELECT
    i_web.i_category AS category,
    td_web.t_hour AS hour_of_day,
    CAST(NULL AS varchar) AS market_manager,
    wp.wp_type AS page_type,
    CAST(NULL AS decimal(7,2)) AS total_net_profit,
    CAST(NULL AS decimal(7,2)) AS total_sales,
    SUM(wr.wr_return_quantity) AS total_return_qty,
    SUM(wr.wr_net_loss) AS total_return_loss,
    CASE
      WHEN SUM(wr.wr_net_loss) > 0 THEN 'Loss'
      ELSE 'NoLoss'
    END AS profit_flag
  FROM web_returns wr
  JOIN time_dim td_web
    ON wr.wr_returned_time_sk = td_web.t_time_sk
  JOIN item i_web
    ON wr.wr_item_sk = i_web.i_item_sk
  JOIN web_page wp
    ON wr.wr_web_page_sk = wp.wp_web_page_sk
  WHERE wp.wp_autogen_flag = 'N'
  GROUP BY
    i_web.i_category,
    td_web.t_hour,
    wp.wp_type
)

SELECT
  category,
  hour_of_day,
  market_manager,
  page_type,
  SUM(COALESCE(total_net_profit, 0)) AS total_net_profit,
  SUM(COALESCE(total_sales, 0)) AS total_sales,
  SUM(COALESCE(total_return_qty, 0)) AS total_return_qty,
  SUM(COALESCE(total_return_loss, 0)) AS total_return_loss,
  CASE
    WHEN SUM(COALESCE(total_net_profit, 0)) - SUM(COALESCE(total_return_loss, 0)) > 0 THEN 'Profit'
    ELSE 'Loss'
  END AS overall_profit_flag
FROM (
  SELECT * FROM catalog_agg
  UNION ALL
  SELECT * FROM web_agg
) combined
GROUP BY GROUPING SETS (
  (category, hour_of_day, market_manager, page_type),
  (category, hour_of_day, market_manager),
  (category, hour_of_day, page_type),
  (category, hour_of_day),
  (category),
  ()
)
ORDER BY total_net_profit DESC
LIMIT 100
