WITH
    sub_sales AS (
        SELECT DISTINCT ws.ws_order_number
        FROM web_sales ws
        JOIN web_site wsi ON ws.ws_web_site_sk = wsi.web_site_sk
        WHERE regexp_like(wsi.web_site_id, '^A{8}K')
    ),
    sub_returns AS (
        SELECT DISTINCT wr.wr_order_number AS ws_order_number
        FROM web_returns wr
        JOIN web_sales ws ON wr.wr_order_number = ws.ws_order_number
                         AND wr.wr_item_sk = ws.ws_item_sk
        JOIN web_site wsi ON ws.ws_web_site_sk = wsi.web_site_sk
        WHERE wsi.web_street_name LIKE '%Cedar%'
          AND regexp_like(wsi.web_site_id, 'K[A-Z]{2}$')
    ),
    intersect_orders AS (
        SELECT ws_order_number FROM sub_sales
        INTERSECT
        SELECT ws_order_number FROM sub_returns
    ),
    agg AS (
        SELECT
            wsi.web_site_id,
            wsi.web_street_name,
            regexp_extract(wsi.web_site_id, '^(A{8})([A-Z])', 2) AS site_suffix,
            concat(wsi.web_city, '_', wsi.web_state) AS city_state,
            SUM(wr.wr_net_loss) AS total_return_loss,
            SUM(ws.ws_net_paid) AS total_net_paid,
            COUNT(DISTINCT ws.ws_order_number) AS order_cnt
        FROM intersect_orders io
        JOIN web_sales ws ON ws.ws_order_number = io.ws_order_number
        JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
                             AND wr.wr_item_sk = ws.ws_item_sk
        JOIN web_site wsi ON ws.ws_web_site_sk = wsi.web_site_sk
        GROUP BY
            wsi.web_site_id,
            wsi.web_street_name,
            regexp_extract(wsi.web_site_id, '^(A{8})([A-Z])', 2),
            concat(wsi.web_city, '_', wsi.web_state)
    )
SELECT
    web_site_id,
    web_street_name,
    site_suffix,
    city_state,
    total_return_loss,
    total_net_paid,
    order_cnt,
    rn
FROM (
    SELECT
        *,
        ROW_NUMBER() OVER (PARTITION BY web_site_id ORDER BY total_return_loss DESC) AS rn
    FROM agg
) t
WHERE rn <= 5
ORDER BY total_return_loss DESC
LIMIT 100
