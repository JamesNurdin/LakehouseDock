SELECT
    d.d_year,
    d.d_month_seq AS month,
    i.i_category,
    sm.sm_type AS ship_mode,
    SUM(cs.cs_quantity) AS total_quantity_sold,
    SUM(cs.cs_ext_sales_price) AS total_sales_amount,
    SUM(cs.cs_net_profit) AS total_net_profit,
    COALESCE(SUM(cr.cr_return_quantity), 0) AS total_quantity_returned,
    COALESCE(SUM(cr.cr_return_amount), 0) AS total_return_amount,
    COALESCE(SUM(cr.cr_net_loss), 0) AS total_net_loss,
    SUM(cs.cs_net_profit) - COALESCE(SUM(cr.cr_net_loss), 0) AS net_profit_after_returns
FROM catalog_sales cs
JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
JOIN item i ON cs.cs_item_sk = i.i_item_sk
JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
LEFT JOIN catalog_returns cr
      ON cs.cs_order_number = cr.cr_order_number
     AND cs.cs_item_sk = cr.cr_item_sk
WHERE d.d_year = 2001
  AND sm.sm_type = 'AIR'
GROUP BY
    d.d_year,
    d.d_month_seq,
    i.i_category,
    sm.sm_type
ORDER BY
    net_profit_after_returns DESC
LIMIT 20
