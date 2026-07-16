SELECT
    d_sale.d_year,
    i.i_category,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    SUM(cs.cs_net_paid_inc_tax) AS total_sales,
    SUM(cs.cs_net_profit) AS total_profit,
    SUM(cr.cr_net_loss) AS total_return_loss,
    COUNT(DISTINCT cs.cs_order_number) AS num_orders,
    AVG(date_diff('day', d_sale.d_date, d_return.d_date)) AS avg_days_to_return,
    SUM(CASE WHEN p.p_promo_sk IS NOT NULL THEN cs.cs_ext_discount_amt ELSE 0 END) AS total_promo_discount
FROM catalog_sales cs
JOIN catalog_returns cr
    ON cs.cs_order_number = cr.cr_order_number
    AND cs.cs_item_sk = cr.cr_item_sk
JOIN date_dim d_sale
    ON cs.cs_sold_date_sk = d_sale.d_date_sk
JOIN date_dim d_return
    ON cr.cr_returned_date_sk = d_return.d_date_sk
JOIN item i
    ON cs.cs_item_sk = i.i_item_sk
LEFT JOIN promotion p
    ON i.i_item_sk = p.p_item_sk
    AND d_sale.d_date_sk BETWEEN p.p_start_date_sk AND p.p_end_date_sk
JOIN household_demographics hd
    ON cr.cr_returning_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
WHERE d_sale.d_year = 2001
  AND i.i_category IN ('Electronics', 'Books', 'Clothing')
GROUP BY d_sale.d_year, i.i_category, ib.ib_lower_bound, ib.ib_upper_bound
HAVING SUM(cs.cs_net_paid_inc_tax) > 10000
ORDER BY total_return_loss DESC
LIMIT 20
