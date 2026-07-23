WITH call_center_extracted AS (
    SELECT
        cc_call_center_sk,
        cc_name,
        cc_city,
        cc_state,
        regexp_extract(cc_street_name, '(Center.*)', 1) AS center_street,
        substr(cc_street_name, 1, 10) AS street_prefix,
        concat(cc_city, ', ', cc_state) AS city_state
    FROM call_center
    WHERE cc_country = 'United States'
      AND regexp_like(cc_street_name, 'Center')
      AND cc_city LIKE 'C%'
)
SELECT
    cce.cc_name,
    cce.city_state,
    cce.center_street,
    w.w_warehouse_name,
    SUM(cr.cr_net_loss) AS total_catalog_net_loss,
    SUM(wr.wr_net_loss) AS total_web_net_loss,
    COUNT(DISTINCT cr.cr_order_number) AS catalog_order_cnt,
    COUNT(DISTINCT ws.ws_order_number) AS web_order_cnt,
    AVG(wr.wr_return_ship_cost) AS avg_web_return_ship_cost,
    (SELECT AVG(wr2.wr_net_loss) FROM web_returns wr2) AS overall_avg_web_net_loss
FROM call_center_extracted cce
JOIN catalog_returns cr
    ON cr.cr_call_center_sk = cce.cc_call_center_sk
JOIN warehouse w
    ON cr.cr_warehouse_sk = w.w_warehouse_sk
JOIN web_sales ws
    ON ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN web_returns wr
    ON wr.wr_item_sk = ws.ws_item_sk
   AND wr.wr_order_number = ws.ws_order_number
WHERE EXISTS (
    SELECT 1
    FROM catalog_returns cr2
    WHERE cr2.cr_call_center_sk = cce.cc_call_center_sk
      AND cr2.cr_fee > 50
      AND cr2.cr_refunded_cash > 100
)
GROUP BY
    cce.cc_name,
    cce.city_state,
    cce.center_street,
    w.w_warehouse_name
ORDER BY total_catalog_net_loss DESC
LIMIT 100
