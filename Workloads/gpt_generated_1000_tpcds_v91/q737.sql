WITH site_avg_profit AS (
    SELECT 
        ws.ws_web_site_sk,
        AVG(ws.ws_net_profit) AS avg_net_profit
    FROM web_sales ws
    GROUP BY ws.ws_web_site_sk
),
non_returned_sales AS (
    SELECT ws.ws_order_number
    FROM web_sales ws
    WHERE ws.ws_quantity > 0
    EXCEPT
    SELECT cr.cr_order_number
    FROM catalog_returns cr
    WHERE cr.cr_return_quantity > 0
)
SELECT 
    ws.ws_order_number,
    ws.ws_sold_date_sk,
    d.d_date,
    c.c_customer_id,
    s.web_name,
    cc.cc_name,
    cp.cp_description,
    r.r_reason_desc,
    ws.ws_quantity,
    ws.ws_net_profit,
    CASE 
        WHEN ws.ws_net_profit > 0 THEN 'Profit' 
        ELSE 'Loss' 
    END AS profit_status,
    AVG(ws.ws_net_profit) OVER (
        PARTITION BY s.web_name 
        ORDER BY d.d_date 
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS running_avg_profit,
    ROW_NUMBER() OVER (
        PARTITION BY s.web_name 
        ORDER BY ws.ws_net_profit DESC
    ) AS profit_rank,
    LAG(ws.ws_net_profit, 1, 0) OVER (
        PARTITION BY s.web_name 
        ORDER BY d.d_date
    ) AS prev_day_profit,
    (
        SELECT spa.avg_net_profit
        FROM site_avg_profit spa
        WHERE spa.ws_web_site_sk = ws.ws_web_site_sk
    ) AS site_avg_profit
FROM web_sales ws
JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN web_site s ON ws.ws_web_site_sk = s.web_site_sk
LEFT JOIN web_returns wr ON ws.ws_order_number = wr.wr_order_number
LEFT JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
LEFT JOIN call_center cc ON d.d_date_sk = cc.cc_open_date_sk
LEFT JOIN catalog_page cp ON d.d_date_sk = cp.cp_start_date_sk
LEFT JOIN catalog_returns cr ON d.d_date_sk = cr.cr_returned_date_sk
WHERE 
    d.d_year = 2002
    AND d.d_month_seq BETWEEN 1 AND 12
    AND s.web_open_date_sk <= d.d_date_sk
    AND s.web_close_date_sk >= d.d_date_sk
    AND cc.cc_gmt_offset BETWEEN -5.00 AND 5.00
    AND ws.ws_quantity > 0
    AND ws.ws_net_profit IS NOT NULL
    AND ws.ws_order_number IN (SELECT ws_order_number FROM non_returned_sales)
ORDER BY 
    s.web_name ASC,
    profit_rank ASC
LIMIT 100
