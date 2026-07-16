SELECT
    d.d_year,
    d.d_month_seq,
    s.s_store_name,
    COUNT(DISTINCT cs.cs_order_number) AS total_orders,
    SUM(cs.cs_net_paid) AS total_net_paid,
    SUM(cs.cs_net_profit) AS total_net_profit,
    SUM(cr.cr_net_loss) AS total_catalog_return_loss,
    SUM(wr.wr_net_loss) AS total_web_return_loss,
    SUM(cs.cs_net_profit) - SUM(cr.cr_net_loss) - SUM(wr.wr_net_loss) AS net_profit_after_returns,
    SUM(cr.cr_fee) AS total_catalog_return_fee,
    SUM(wr.wr_fee) AS total_web_return_fee,
    AVG(cs.cs_quantity) AS avg_quantity,
    SUM(cs.cs_ext_discount_amt) AS total_discount_amount,
    MIN(d.d_date) AS first_transaction_date,
    MAX(d.d_date) AS last_transaction_date
FROM catalog_sales cs
JOIN date_dim d
    ON cs.cs_sold_date_sk = d.d_date_sk
JOIN catalog_returns cr
    ON cr.cr_item_sk = cs.cs_item_sk
   AND cr.cr_order_number = cs.cs_order_number
   AND cr.cr_returned_date_sk = d.d_date_sk
JOIN web_returns wr
    ON wr.wr_returned_date_sk = d.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
GROUP BY d.d_year, d.d_month_seq, s.s_store_name
ORDER BY total_net_paid DESC
LIMIT 100
