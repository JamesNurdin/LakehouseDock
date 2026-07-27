WITH returns_agg AS (
    SELECT
        cr.cr_warehouse_sk AS warehouse_sk,
        SUM(cr.cr_net_loss) AS total_return_loss,
        COUNT(*) AS return_cnt
    FROM catalog_returns cr
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN time_dim td ON cr.cr_returned_time_sk = td.t_time_sk
    WHERE w.w_street_number LIKE '9%'
      AND td.t_hour BETWEEN 8 AND 12
    GROUP BY cr.cr_warehouse_sk
),
sales_agg AS (
    SELECT
        ws.ws_warehouse_sk AS warehouse_sk,
        SUM(ws.ws_net_profit) AS total_sales_profit,
        COUNT(*) AS sales_cnt,
        REGEXP_EXTRACT(p.p_channel_details, '(?i)high') AS high_word
    FROM web_sales ws
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
    WHERE p.p_channel_tv = 'N'
      AND REGEXP_LIKE(p.p_channel_details, '(?i)high')
      AND p.p_promo_name LIKE '%Sale%'
      AND td.t_hour BETWEEN 8 AND 12
    GROUP BY ws.ws_warehouse_sk, REGEXP_EXTRACT(p.p_channel_details, '(?i)high')
)
SELECT
    CONCAT(w.w_warehouse_name, ' - ', w.w_city) AS warehouse_full_name,
    r.total_return_loss,
    r.return_cnt,
    s.total_sales_profit,
    s.sales_cnt,
    s.high_word
FROM returns_agg r
JOIN sales_agg s ON r.warehouse_sk = s.warehouse_sk
JOIN warehouse w ON w.w_warehouse_sk = r.warehouse_sk
ORDER BY r.total_return_loss DESC
LIMIT 10
