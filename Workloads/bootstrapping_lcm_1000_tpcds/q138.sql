SELECT
    d_ret.d_year AS return_year,
    d_ret.d_month_seq AS return_month,
    s.s_state AS store_state,
    w.web_state AS website_state,
    CASE
        WHEN d_ret.d_month_seq BETWEEN 1 AND 3 THEN 'Q1'
        WHEN d_ret.d_month_seq BETWEEN 4 AND 6 THEN 'Q2'
        WHEN d_ret.d_month_seq BETWEEN 7 AND 9 THEN 'Q3'
        ELSE 'Q4'
    END AS return_quarter,
    COUNT(*) AS total_transactions,
    SUM(cs.cs_net_paid) AS total_sales,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cs.cs_net_profit) - SUM(cr.cr_net_loss) AS net_profit_after_returns,
    AVG(cs.cs_ext_discount_amt) AS avg_discount,
    SUM(CASE WHEN cs.cs_quantity > 5 THEN cs.cs_sales_price * cs.cs_quantity ELSE 0 END) AS high_qty_sales,
    SUM(CASE WHEN cr.cr_return_quantity > 0 THEN cr.cr_return_amount ELSE 0 END) AS total_returned_amount,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_sales_orders,
    COUNT(DISTINCT cr.cr_order_number) AS distinct_return_orders
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
GROUP BY
    d_ret.d_year,
    d_ret.d_month_seq,
    s.s_state,
    w.web_state,
    CASE
        WHEN d_ret.d_month_seq BETWEEN 1 AND 3 THEN 'Q1'
        WHEN d_ret.d_month_seq BETWEEN 4 AND 6 THEN 'Q2'
        WHEN d_ret.d_month_seq BETWEEN 7 AND 9 THEN 'Q3'
        ELSE 'Q4'
    END
HAVING SUM(cs.cs_net_paid) > 10000
ORDER BY total_sales DESC
LIMIT 100
