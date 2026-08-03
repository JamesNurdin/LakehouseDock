WITH cs_agg AS (
    SELECT
        cs_ship_mode_sk,
        SUM(cs_ext_sales_price) AS total_cs_sales,
        COUNT(*) AS cnt_cs
    FROM catalog_sales
    GROUP BY cs_ship_mode_sk
),
ws_agg AS (
    SELECT
        ws_ship_mode_sk,
        ws_web_site_sk,
        SUM(ws_net_paid_inc_ship_tax) AS total_ws_net_paid,
        AVG(ws_ext_ship_cost) AS avg_ws_ship_cost
    FROM web_sales
    GROUP BY ws_ship_mode_sk, ws_web_site_sk
),
order_numbers AS (
    SELECT ws_order_number AS order_number
    FROM web_sales
    EXCEPT
    SELECT wr_order_number FROM web_returns
)
SELECT
    sm1.sm_type,
    sm1.sm_carrier,
    cs_agg.total_cs_sales,
    cs_agg.cnt_cs,
    ws_agg.total_ws_net_paid,
    ws_agg.avg_ws_ship_cost,
    site.web_name,
    CASE WHEN ws_agg.avg_ws_ship_cost > 500 THEN 'HIGH' ELSE 'NORMAL' END AS ship_cost_category,
    lr.return_cnt,
    COUNT(DISTINCT ws.ws_order_number) AS distinct_orders
FROM cs_agg
INNER JOIN ship_mode sm1
    ON cs_agg.cs_ship_mode_sk = sm1.sm_ship_mode_sk
RIGHT OUTER JOIN ship_mode sm2
    ON cs_agg.cs_ship_mode_sk = sm2.sm_ship_mode_sk
INNER JOIN ws_agg
    ON cs_agg.cs_ship_mode_sk = ws_agg.ws_ship_mode_sk
INNER JOIN ship_mode sm3
    ON ws_agg.ws_ship_mode_sk = sm3.sm_ship_mode_sk
RIGHT OUTER JOIN ship_mode sm4
    ON ws_agg.ws_ship_mode_sk = sm4.sm_ship_mode_sk
INNER JOIN web_site site
    ON ws_agg.ws_web_site_sk = site.web_site_sk
INNER JOIN web_sales ws
    ON ws.ws_ship_mode_sk = sm3.sm_ship_mode_sk
INNER JOIN web_returns wr_item
    ON wr_item.wr_item_sk = ws.ws_item_sk
INNER JOIN web_returns wr_order
    ON wr_order.wr_order_number = ws.ws_order_number
LEFT JOIN LATERAL (
    SELECT COUNT(*) AS return_cnt
    FROM web_returns r
    WHERE r.wr_order_number = ws.ws_order_number
) lr ON TRUE
WHERE ws.ws_order_number IN (SELECT order_number FROM order_numbers)
GROUP BY
    sm1.sm_type,
    sm1.sm_carrier,
    cs_agg.total_cs_sales,
    cs_agg.cnt_cs,
    ws_agg.total_ws_net_paid,
    ws_agg.avg_ws_ship_cost,
    site.web_name,
    CASE WHEN ws_agg.avg_ws_ship_cost > 500 THEN 'HIGH' ELSE 'NORMAL' END,
    lr.return_cnt
ORDER BY ws_agg.total_ws_net_paid DESC
OFFSET 0 ROWS FETCH FIRST 100 ROWS ONLY
