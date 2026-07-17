SELECT
    d_sold.d_year AS year,
    d_sold.d_month_seq AS month_seq,
    cc.cc_name AS call_center_name,
    SUM(cs.cs_net_profit) AS total_net_profit,
    SUM(cr.cr_net_loss) AS total_return_loss,
    SUM(cs.cs_net_profit) - COALESCE(SUM(cr.cr_net_loss), 0) AS net_contribution
FROM catalog_sales cs
JOIN date_dim d_sold
    ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN call_center cc
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN item i
    ON cs.cs_item_sk = i.i_item_sk
LEFT JOIN catalog_returns cr
    ON cs.cs_order_number = cr.cr_order_number
   AND cr.cr_call_center_sk = cc.cc_call_center_sk
WHERE d_sold.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
  AND i.i_category = 'Sports'
  AND cs.cs_call_center_sk IN (40, 37, 38)
GROUP BY d_sold.d_year, d_sold.d_month_seq, cc.cc_name
ORDER BY d_sold.d_year, d_sold.d_month_seq, cc.cc_name
