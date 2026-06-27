SELECT
    cp.cp_department,
    ds.d_year,
    ds.d_month_seq AS month_seq,
    SUM(cs.cs_ext_sales_price) AS total_sales_amount,
    SUM(cs.cs_net_profit) AS total_net_profit,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_net_loss) AS total_net_loss,
    SUM(cs.cs_net_profit) - COALESCE(SUM(cr.cr_net_loss), 0) AS net_profit_after_returns,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
    COUNT(DISTINCT cr.cr_returned_date_sk) AS distinct_return_dates
FROM catalog_sales cs
JOIN date_dim ds
    ON cs.cs_sold_date_sk = ds.d_date_sk
JOIN catalog_page cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
LEFT JOIN catalog_returns cr
    ON cs.cs_order_number = cr.cr_order_number
   AND cs.cs_item_sk = cr.cr_item_sk
   AND cs.cs_catalog_page_sk = cr.cr_catalog_page_sk
LEFT JOIN date_dim dr
    ON cr.cr_returned_date_sk = dr.d_date_sk
WHERE ds.d_date BETWEEN DATE '2020-01-01' AND DATE '2020-12-31'
  AND (dr.d_date IS NULL OR dr.d_date BETWEEN DATE '2020-01-01' AND DATE '2020-12-31')
GROUP BY cp.cp_department, ds.d_year, ds.d_month_seq
ORDER BY net_profit_after_returns DESC
LIMIT 100
