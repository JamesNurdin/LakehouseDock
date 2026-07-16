SELECT
    cc.cc_division_name,
    s.s_division_name,
    d_date.d_year,
    d_date.d_month_seq,
    COUNT(DISTINCT ws.ws_order_number) AS orders,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    SUM(ws.ws_net_profit) AS total_profit,
    COALESCE(SUM(wr.wr_return_amt), 0) AS total_returns,
    COALESCE(SUM(wr.wr_net_loss), 0) AS total_return_loss,
    (SUM(ws.ws_net_profit) - COALESCE(SUM(wr.wr_net_loss), 0)) AS profit_after_returns,
    AVG(cc.cc_tax_percentage) AS avg_cc_tax_pct,
    AVG(s.s_tax_percentage) AS avg_store_tax_pct
FROM
    call_center cc
    JOIN date_dim d_date ON cc.cc_closed_date_sk = d_date.d_date_sk
    LEFT JOIN date_dim d_open ON cc.cc_open_date_sk = d_open.d_date_sk
    JOIN store s ON s.s_closed_date_sk = d_date.d_date_sk
    JOIN web_sales ws ON ws.ws_sold_date_sk = d_date.d_date_sk
    LEFT JOIN date_dim d_ship ON ws.ws_ship_date_sk = d_ship.d_date_sk
    LEFT JOIN web_returns wr ON wr.wr_item_sk = ws.ws_item_sk
        AND wr.wr_order_number = ws.ws_order_number
        AND wr.wr_returned_date_sk = d_date.d_date_sk
WHERE
    d_date.d_year = 2001
GROUP BY
    cc.cc_division_name,
    s.s_division_name,
    d_date.d_year,
    d_date.d_month_seq
HAVING
    SUM(ws.ws_ext_sales_price) > 100000
ORDER BY
    profit_after_returns DESC
LIMIT 100
