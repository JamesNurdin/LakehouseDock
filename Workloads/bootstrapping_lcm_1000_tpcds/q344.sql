SELECT
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    s.s_state,
    d.d_year,
    d.d_moy AS month,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    SUM(ss.ss_net_profit) AS total_net_profit,
    SUM(cr.cr_net_loss) AS total_return_loss,
    SUM(cr.cr_fee) AS total_return_fees,
    COUNT(DISTINCT ss.ss_ticket_number) AS distinct_sales_tickets,
    COUNT(DISTINCT cr.cr_order_number) AS distinct_return_orders,
    CASE
        WHEN SUM(ss.ss_ext_sales_price) = 0 THEN NULL
        ELSE SUM(cr.cr_net_loss) / SUM(ss.ss_ext_sales_price)
    END AS loss_to_sales_ratio,
    CASE
        WHEN SUM(ss.ss_quantity) = 0 THEN NULL
        ELSE SUM(ss.ss_ext_discount_amt) / SUM(ss.ss_quantity)
    END AS avg_discount_per_item
FROM store_sales ss
JOIN date_dim d
    ON ss.ss_sold_date_sk = d.d_date_sk
JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
JOIN date_dim d_closed
    ON s.s_closed_date_sk = d_closed.d_date_sk
JOIN catalog_returns cr
    ON cr.cr_returned_date_sk = d.d_date_sk
WHERE d.d_year BETWEEN 2015 AND 2020
  AND s.s_state IS NOT NULL
GROUP BY
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    s.s_state,
    d.d_year,
    d.d_moy
HAVING SUM(ss.ss_ext_sales_price) > 1000
ORDER BY total_net_profit DESC
LIMIT 100
