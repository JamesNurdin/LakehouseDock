SELECT
    d_ret.d_year AS return_year,
    CASE WHEN d_ret.d_month_seq <= 6 THEN 'H1' ELSE 'H2' END AS half_year,
    s.s_state AS store_state,
    ws_open.web_state AS web_state,
    COUNT(DISTINCT cr.cr_order_number) AS distinct_orders,
    SUM(cr.cr_net_loss) AS total_net_loss,
    SUM(cs.cs_net_paid) AS total_net_paid,
    AVG(cs.cs_quantity) AS avg_quantity,
    SUM(CASE WHEN cs.cs_net_profit > 0 THEN cs.cs_net_profit ELSE 0 END) AS total_positive_profit,
    SUM(CASE WHEN cs.cs_net_profit < 0 THEN cs.cs_net_profit ELSE 0 END) AS total_negative_profit,
    COUNT(*) FILTER (WHERE ws_open.web_gmt_offset > 0) AS cnt_gmt_positive,
    SUM(cr.cr_return_quantity * cs.cs_sales_price) AS total_return_sales_value,
    SUM(cs.cs_ext_tax) AS total_tax,
    SUM(cs.cs_ext_discount_amt) AS total_discount,
    SUM(cs.cs_ext_ship_cost) AS total_ship_cost
FROM catalog_returns cr
INNER JOIN catalog_sales cs
    ON cr.cr_item_sk = cs.cs_item_sk
    AND cr.cr_order_number = cs.cs_order_number
INNER JOIN date_dim d_ret
    ON cr.cr_returned_date_sk = d_ret.d_date_sk
INNER JOIN date_dim d_sold
    ON cs.cs_sold_date_sk = d_sold.d_date_sk
INNER JOIN date_dim d_ship
    ON cs.cs_ship_date_sk = d_ship.d_date_sk
INNER JOIN store s
    ON s.s_closed_date_sk = d_ret.d_date_sk
INNER JOIN web_site ws_open
    ON ws_open.web_open_date_sk = d_ret.d_date_sk
INNER JOIN web_site ws_close
    ON ws_close.web_close_date_sk = d_ret.d_date_sk
WHERE d_ret.d_year BETWEEN 2000 AND 2005
GROUP BY
    d_ret.d_year,
    CASE WHEN d_ret.d_month_seq <= 6 THEN 'H1' ELSE 'H2' END,
    s.s_state,
    ws_open.web_state
HAVING COUNT(*) > 100
ORDER BY total_net_loss DESC
LIMIT 50
