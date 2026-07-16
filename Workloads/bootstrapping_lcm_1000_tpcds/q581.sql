SELECT
    COALESCE(cc.cc_company_name, 'All Companies') AS company_name,
    COALESCE(s.s_state, 'All States') AS store_state,
    COALESCE(CAST(dr.d_year AS VARCHAR), 'All Years') AS return_year,
    COALESCE(CAST(dr.d_month_seq AS VARCHAR), 'All Months') AS return_month,
    COUNT(DISTINCT cr.cr_order_number) AS num_returns,
    COUNT(DISTINCT ws.ws_order_number) AS num_sales,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(ws.ws_ext_sales_price) AS total_sales_amount,
    SUM(ws.ws_net_profit) AS total_net_profit,
    CASE
        WHEN SUM(ws.ws_ext_sales_price) > 0 THEN SUM(ws.ws_net_profit) / SUM(ws.ws_ext_sales_price)
        ELSE NULL
    END AS profit_margin,
    CASE
        WHEN SUM(ws.ws_net_profit) / NULLIF(SUM(ws.ws_ext_sales_price), 0) > 0.3 THEN 'High'
        WHEN SUM(ws.ws_net_profit) / NULLIF(SUM(ws.ws_ext_sales_price), 0) IS NULL THEN 'N/A'
        ELSE 'Low'
    END AS profit_category,
    SUM(ws.ws_ext_sales_price) - SUM(cr.cr_return_amount) AS net_sales_minus_returns
FROM call_center cc
JOIN catalog_returns cr
    ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN date_dim dr
    ON cr.cr_returned_date_sk = dr.d_date_sk
JOIN web_sales ws
    ON ws.ws_sold_date_sk = dr.d_date_sk
JOIN date_dim dship
    ON ws.ws_ship_date_sk = dship.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = dr.d_date_sk
JOIN date_dim dcall
    ON cc.cc_closed_date_sk = dcall.d_date_sk
WHERE dr.d_year BETWEEN 2001 AND 2003
  AND dcall.d_year BETWEEN 2000 AND 2005
GROUP BY ROLLUP (cc.cc_company_name, s.s_state, dr.d_year, dr.d_month_seq)
HAVING COUNT(DISTINCT cr.cr_order_number) > 0
ORDER BY total_sales_amount DESC
LIMIT 100
