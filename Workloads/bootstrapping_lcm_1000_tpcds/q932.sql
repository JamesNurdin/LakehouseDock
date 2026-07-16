SELECT
    s.s_store_id,
    dr.d_year AS return_year,
    ds.d_month_seq AS sale_month,
    SUM(cs.cs_net_paid) AS total_sales,
    SUM(cs.cs_net_profit) AS total_profit,
    SUM(cr.cr_net_loss) AS total_return_loss,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
    AVG(cs.cs_quantity) AS avg_quantity_sold,
    SUM(cs.cs_ext_discount_amt) AS total_discount,
    SUM(cs.cs_ext_tax) AS total_tax,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cs.cs_net_paid) - SUM(cr.cr_net_loss) AS net_profit_after_returns,
    CASE WHEN SUM(cs.cs_net_profit) > 0 THEN 'POSITIVE' ELSE 'NEGATIVE' END AS profit_indicator
FROM catalog_returns cr
JOIN date_dim dr
    ON cr.cr_returned_date_sk = dr.d_date_sk
JOIN catalog_sales cs
    ON cr.cr_item_sk = cs.cs_item_sk
   AND cr.cr_order_number = cs.cs_order_number
JOIN date_dim ds
    ON cs.cs_sold_date_sk = ds.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = dr.d_date_sk
WHERE dr.d_year BETWEEN 2000 AND 2005
  AND s.s_state = 'CA'
GROUP BY s.s_store_id, dr.d_year, ds.d_month_seq
HAVING SUM(cs.cs_net_paid) > 1000
ORDER BY net_profit_after_returns DESC
LIMIT 100
