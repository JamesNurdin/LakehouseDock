SELECT
    reason_desc,
    store_state,
    year,
    quarter,
    returns_cnt,
    total_return_loss,
    avg_return_amount,
    sales_cnt,
    total_sales_profit,
    total_sales_amount,
    loss_to_sales_ratio,
    ROW_NUMBER() OVER (PARTITION BY reason_desc ORDER BY total_sales_profit DESC) AS profit_rank
FROM (
    SELECT
        r.r_reason_desc AS reason_desc,
        s.s_state AS store_state,
        d.d_year AS year,
        d.d_quarter_name AS quarter,
        COUNT(DISTINCT cr.cr_order_number) AS returns_cnt,
        SUM(cr.cr_net_loss) AS total_return_loss,
        AVG(cr.cr_return_amount) AS avg_return_amount,
        COUNT(DISTINCT ws.ws_order_number) AS sales_cnt,
        SUM(ws.ws_net_profit) AS total_sales_profit,
        SUM(ws.ws_ext_sales_price) AS total_sales_amount,
        CASE WHEN SUM(ws.ws_ext_sales_price) = 0 THEN NULL
             ELSE ROUND(SUM(cr.cr_net_loss) / SUM(ws.ws_ext_sales_price), 4)
        END AS loss_to_sales_ratio
    FROM catalog_returns cr
    JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    JOIN web_sales ws
        ON ws.ws_sold_date_sk = d.d_date_sk
       AND ws.ws_ship_date_sk = d.d_date_sk
    JOIN store s
        ON s.s_closed_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2000 AND 2005
    GROUP BY r.r_reason_desc, s.s_state, d.d_year, d.d_quarter_name
) t
ORDER BY total_sales_profit DESC
LIMIT 100
