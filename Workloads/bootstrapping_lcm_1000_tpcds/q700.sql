SELECT
    cp.cp_type,
    d_ret.d_year,
    COUNT(DISTINCT cr.cr_order_number) AS return_order_cnt,
    SUM(cr.cr_net_loss) AS total_return_net_loss,
    SUM(ws.ws_net_profit) AS total_web_profit,
    COUNT(DISTINCT ws.ws_order_number) AS web_order_cnt,
    AVG(s.s_floor_space) AS avg_store_floor_space,
    SUM(ws.ws_sales_price * ws.ws_quantity) AS total_sales_amount,
    SUM(CASE WHEN cp.cp_type = 'Promotional' THEN cr.cr_return_amount ELSE 0 END) AS promo_return_amount
FROM catalog_page cp
JOIN catalog_returns cr
    ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN date_dim d_ret
    ON cr.cr_returned_date_sk = d_ret.d_date_sk
JOIN web_sales ws
    ON ws.ws_sold_date_sk = d_ret.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_ret.d_date_sk
WHERE d_ret.d_year BETWEEN 2000 AND 2002
  AND cp.cp_type IS NOT NULL
GROUP BY cp.cp_type, d_ret.d_year
HAVING SUM(ws.ws_net_profit) > 0
ORDER BY total_web_profit DESC
LIMIT 100
