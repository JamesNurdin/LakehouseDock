SELECT
    d_ret.d_year,
    d_ret.d_month_seq,
    s.s_state,
    COUNT(DISTINCT cr.cr_order_number)           AS catalog_return_orders,
    SUM(cr.cr_net_loss)                          AS catalog_total_net_loss,
    SUM(cs.cs_net_profit)                        AS catalog_total_net_profit,
    COUNT(DISTINCT wr.wr_order_number)           AS web_return_orders,
    SUM(wr.wr_net_loss)                          AS web_total_net_loss,
    AVG(cs.cs_quantity)                          AS avg_sales_quantity,
    SUM(cs.cs_ext_sales_price)                   AS total_sales_price,
    SUM(cs.cs_ext_discount_amt)                  AS total_discount,
    MIN(d_sold.d_date)                           AS first_sale_date,
    MAX(d_sold.d_date)                           AS last_sale_date
FROM catalog_returns cr
JOIN date_dim d_ret
    ON cr.cr_returned_date_sk = d_ret.d_date_sk
JOIN catalog_sales cs
    ON cr.cr_item_sk = cs.cs_item_sk
   AND cr.cr_order_number = cs.cs_order_number
JOIN date_dim d_sold
    ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN web_returns wr
    ON wr.wr_returned_date_sk = d_ret.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_ret.d_date_sk
WHERE d_ret.d_year BETWEEN 1998 AND 2000
  AND s.s_state IS NOT NULL
GROUP BY d_ret.d_year, d_ret.d_month_seq, s.s_state
HAVING SUM(cr.cr_net_loss) > 0
ORDER BY d_ret.d_year, d_ret.d_month_seq, s.s_state
LIMIT 100
