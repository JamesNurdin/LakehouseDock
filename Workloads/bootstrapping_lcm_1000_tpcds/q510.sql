SELECT
    cp.cp_department,
    cp.cp_catalog_number,
    cp.cp_type,
    rd_ret.d_year AS return_year,
    rd_ret.d_month_seq AS return_month_seq,
    rd_start.d_year AS start_year,
    rd_start.d_month_seq AS start_month_seq,
    rd_end.d_year AS end_year,
    rd_end.d_month_seq AS end_month_seq,
    s.s_state,
    s.s_city,
    s.s_market_desc,
    SUM(cr.cr_net_loss) AS total_return_loss,
    COUNT(DISTINCT cr.cr_order_number) AS num_returns,
    SUM(ws.ws_net_profit) AS total_web_profit,
    COUNT(DISTINCT ws.ws_order_number) AS num_web_sales,
    AVG(ws.ws_quantity) AS avg_quantity,
    SUM(ws.ws_ext_sales_price) AS total_sales_price
FROM catalog_page cp
JOIN catalog_returns cr ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN date_dim rd_ret ON cr.cr_returned_date_sk = rd_ret.d_date_sk
JOIN date_dim rd_start ON cp.cp_start_date_sk = rd_start.d_date_sk
JOIN date_dim rd_end ON cp.cp_end_date_sk = rd_end.d_date_sk
JOIN web_sales ws ON ws.ws_sold_date_sk = rd_ret.d_date_sk
JOIN date_dim rd_ship ON ws.ws_ship_date_sk = rd_ship.d_date_sk
JOIN store s ON s.s_closed_date_sk = rd_end.d_date_sk
WHERE cp.cp_type = 'catalog'
GROUP BY
    cp.cp_department,
    cp.cp_catalog_number,
    cp.cp_type,
    rd_ret.d_year,
    rd_ret.d_month_seq,
    rd_start.d_year,
    rd_start.d_month_seq,
    rd_end.d_year,
    rd_end.d_month_seq,
    s.s_state,
    s.s_city,
    s.s_market_desc
ORDER BY total_return_loss DESC
LIMIT 100
