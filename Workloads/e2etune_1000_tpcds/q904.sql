WITH
    sales_by_shift AS (
        SELECT
            td.t_shift,
            SUM(ws.ws_ext_sales_price) AS total_sales,
            SUM(ws.ws_net_profit) AS total_profit,
            COUNT(*) AS sales_cnt
        FROM web_sales ws
        JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
        JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
        WHERE p.p_channel_tv = 'Y'
        GROUP BY td.t_shift
    ),
    returns_by_shift AS (
        SELECT
            td.t_shift,
            SUM(cr.cr_return_amount) AS total_returns,
            SUM(cr.cr_net_loss) AS total_loss,
            COUNT(*) AS returns_cnt
        FROM catalog_returns cr
        JOIN time_dim td ON cr.cr_returned_time_sk = td.t_time_sk
        WHERE cr.cr_return_quantity > 0
        GROUP BY td.t_shift
    )
SELECT
    s.t_shift,
    s.total_sales,
    COALESCE(r.total_returns, 0) AS total_returns,
    s.total_sales - COALESCE(r.total_returns, 0) AS net_margin,
    RANK() OVER (ORDER BY s.total_sales - COALESCE(r.total_returns, 0) DESC) AS margin_rank
FROM sales_by_shift s
LEFT JOIN returns_by_shift r ON s.t_shift = r.t_shift
ORDER BY net_margin DESC
