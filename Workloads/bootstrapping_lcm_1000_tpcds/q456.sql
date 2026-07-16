SELECT
    d_ret.d_year AS return_year,
    d_ret.d_month_seq AS return_month_seq,
    s.s_store_id,
    s.s_store_name,
    w.web_site_id,
    w.web_name,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
    SUM(cs.cs_net_paid) AS total_net_paid,
    SUM(cs.cs_net_profit) AS total_net_profit,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_net_loss) AS total_net_loss,
    SUM(cr.cr_return_quantity) AS total_return_quantity,
    CASE 
        WHEN SUM(cs.cs_net_paid) > 0 THEN SUM(cr.cr_return_amount) / SUM(cs.cs_net_paid)
        ELSE NULL
    END AS return_to_sales_ratio,
    COUNT(*) FILTER (WHERE d_sold.d_year = d_ret.d_year) AS orders_same_year_as_return,
    SUM(cs.cs_ext_tax) FILTER (WHERE d_ship.d_month_seq = d_ret.d_month_seq) AS tax_on_ship_month,
    AVG(cs.cs_quantity) AS avg_quantity
FROM catalog_returns cr
JOIN catalog_sales cs
    ON cr.cr_item_sk = cs.cs_item_sk
    AND cr.cr_order_number = cs.cs_order_number
JOIN date_dim d_ret
    ON cr.cr_returned_date_sk = d_ret.d_date_sk
JOIN date_dim d_sold
    ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
    ON cs.cs_ship_date_sk = d_ship.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_ret.d_date_sk
JOIN web_site w
    ON w.web_open_date_sk = d_ret.d_date_sk
JOIN date_dim d_web_close
    ON w.web_close_date_sk = d_web_close.d_date_sk
WHERE d_ret.d_year = 2001
GROUP BY
    d_ret.d_year,
    d_ret.d_month_seq,
    s.s_store_id,
    s.s_store_name,
    w.web_site_id,
    w.web_name
HAVING COUNT(DISTINCT cs.cs_order_number) > 5
ORDER BY total_net_paid DESC
LIMIT 100
