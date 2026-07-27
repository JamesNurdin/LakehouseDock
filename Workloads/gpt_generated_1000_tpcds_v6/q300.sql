WITH avg_net_profit AS (
    SELECT AVG(ws.ws_net_profit) AS avg_profit
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
)

SELECT
    r.r_reason_desc AS category,
    SUM(cr.cr_return_amount) AS total_amount,
    COUNT(*) AS transaction_cnt,
    (SELECT avg_profit FROM avg_net_profit) AS avg_yearly_net_profit,
    'Return' AS source_type
FROM catalog_returns cr
JOIN date_dim d_ret ON cr.cr_returned_date_sk = d_ret.d_date_sk
JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
WHERE d_ret.d_year = 2001
  AND cc.cc_state = 'CA'
GROUP BY r.r_reason_desc

UNION ALL

SELECT
    p.p_promo_name AS category,
    SUM(ws.ws_ext_sales_price) AS total_amount,
    COUNT(*) AS transaction_cnt,
    (SELECT avg_profit FROM avg_net_profit) AS avg_yearly_net_profit,
    'Sales' AS source_type
FROM web_sales ws
JOIN date_dim d_sold ON ws.ws_sold_date_sk = d_sold.d_date_sk
JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
WHERE d_sold.d_year = 2001
  AND EXISTS (
        SELECT 1
        FROM web_page wp
        WHERE wp.wp_web_page_sk = ws.ws_web_page_sk
          AND wp.wp_type = 'product'
    )
  AND ws.ws_sold_date_sk BETWEEN p.p_start_date_sk AND p.p_end_date_sk
GROUP BY p.p_promo_name

ORDER BY total_amount DESC
LIMIT 100
