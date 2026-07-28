SELECT
    s.s_state,
    d.d_year,
    wp.wp_type,
    COUNT(DISTINCT ws.ws_order_number) AS order_cnt,
    SUM(cr.cr_net_loss) AS catalog_net_loss,
    SUM(wr.wr_net_loss) AS web_return_net_loss,
    SUM(ws.ws_net_profit) AS total_net_profit,
    AVG(ws.ws_ext_sales_price) AS avg_ext_sales_price,
    MIN(d.d_date) AS min_date,
    MAX(d.d_date) AS max_date
FROM catalog_returns cr
JOIN date_dim d
  ON cr.cr_returned_date_sk = d.d_date_sk
JOIN store s
  ON s.s_closed_date_sk = d.d_date_sk
JOIN web_sales ws
  ON ws.ws_sold_date_sk = d.d_date_sk
JOIN web_page wp
  ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN web_returns wr
  ON wr.wr_order_number = ws.ws_order_number
WHERE
    d.d_date >= DATE '2001-01-01'
    AND d.d_date <= DATE '2001-12-31'
    AND s.s_state = 'TX'
    AND s.s_county = 'Pennington County'
    AND wp.wp_autogen_flag = 'N'
    AND wp.wp_max_ad_count >= 2
    AND cr.cr_return_quantity > 0
GROUP BY
    s.s_state,
    d.d_year,
    wp.wp_type
ORDER BY
    total_net_profit DESC,
    order_cnt DESC
LIMIT 100
