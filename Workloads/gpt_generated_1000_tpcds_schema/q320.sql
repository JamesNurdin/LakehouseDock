WITH ws_base AS (
    SELECT
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_net_paid,
        ws.ws_net_profit,
        ws.ws_warehouse_sk,
        ws.ws_web_site_sk,
        ws.ws_sold_date_sk,
        ws.ws_sold_time_sk,
        ws_site.web_name,
        split(ws_site.web_name, ' ') AS name_parts,
        CASE WHEN ws.ws_quantity > 10 THEN 'Large' ELSE 'Small' END AS qty_category
    FROM web_sales ws
    JOIN web_site ws_site ON ws.ws_web_site_sk = ws_site.web_site_sk
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND regexp_like(ws_site.web_name, '^.*Market.*$')
),
cr_base AS (
    SELECT
        cr.cr_order_number,
        cr.cr_return_quantity,
        cr.cr_return_amount,
        cr.cr_reason_sk,
        cr.cr_returned_date_sk,
        cr.cr_returned_time_sk,
        r.r_reason_desc
    FROM catalog_returns cr
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND r.r_reason_desc LIKE '%defect%'
),
common_orders AS (
    SELECT ws_order_number AS order_number
    FROM ws_base
    INTERSECT
    SELECT cr_order_number
    FROM cr_base
)
SELECT
    co.order_number,
    ws.qty_category,
    ws.ws_net_paid,
    ws.ws_net_profit,
    w.w_warehouse_name,
    regexp_extract(ws.web_name, '^([^ ]+)', 1) AS first_word,
    CASE WHEN ws.ws_net_profit > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_flag,
    part AS name_token
FROM common_orders co
JOIN ws_base ws ON ws.ws_order_number = co.order_number
JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
LEFT JOIN UNNEST(ws.name_parts) AS t (part) ON TRUE
WHERE part LIKE 'M%'
ORDER BY ws.ws_net_paid DESC
LIMIT 100
