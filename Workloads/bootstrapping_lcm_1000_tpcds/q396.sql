SELECT
    s.s_store_id,
    s.s_store_name,
    d.d_year,
    d.d_month_seq,
    SUM(cs.cs_net_paid) AS total_sales_net_paid,
    SUM(cs.cs_net_profit) AS total_sales_profit,
    SUM(cr.cr_net_loss) AS total_catalog_return_loss,
    SUM(sr.sr_net_loss) AS total_store_return_loss,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_sales_orders,
    COUNT(DISTINCT cr.cr_order_number) AS distinct_catalog_returns
FROM catalog_returns cr
JOIN catalog_sales cs
    ON cr.cr_item_sk = cs.cs_item_sk
   AND cr.cr_order_number = cs.cs_order_number
JOIN date_dim d
    ON cr.cr_returned_date_sk = d.d_date_sk
   AND cs.cs_sold_date_sk = d.d_date_sk
   AND cs.cs_ship_date_sk = d.d_date_sk
JOIN store_returns sr
    ON sr.sr_returned_date_sk = d.d_date_sk
JOIN store s
    ON sr.sr_store_sk = s.s_store_sk
   AND s.s_closed_date_sk = d.d_date_sk
WHERE d.d_year BETWEEN 2000 AND 2005
GROUP BY
    s.s_store_id,
    s.s_store_name,
    d.d_year,
    d.d_month_seq
ORDER BY
    d.d_year,
    s.s_store_id
LIMIT 100
