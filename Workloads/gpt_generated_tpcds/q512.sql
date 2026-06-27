SELECT
    d_sold.d_year,
    d_sold.d_moy AS month,
    i.i_category,
    SUM(cs.cs_net_profit) AS total_sales_net_profit,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cs.cs_net_profit) - SUM(cr.cr_return_amount) AS net_profit_after_returns,
    SUM(cs.cs_quantity) AS total_quantity_sold,
    SUM(cr.cr_return_quantity) AS total_return_quantity,
    COUNT(DISTINCT cs.cs_order_number) AS total_orders
FROM catalog_sales cs
JOIN date_dim d_sold
    ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN item i
    ON cs.cs_item_sk = i.i_item_sk
LEFT JOIN catalog_returns cr
    ON cs.cs_order_number = cr.cr_order_number
    AND cs.cs_item_sk = cr.cr_item_sk
LEFT JOIN date_dim d_return
    ON cr.cr_returned_date_sk = d_return.d_date_sk
WHERE d_sold.d_year = 2001
GROUP BY
    d_sold.d_year,
    d_sold.d_moy,
    i.i_category
ORDER BY net_profit_after_returns DESC
