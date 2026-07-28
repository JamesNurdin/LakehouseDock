WITH
    union_vals AS (
        SELECT sm_code AS val FROM ship_mode
        UNION ALL
        SELECT r_reason_id AS val FROM reason
    ),
    avg_discount_cte AS (
        SELECT avg(cs_ext_discount_amt) AS avg_discount FROM catalog_sales
    )
SELECT
    sm1.sm_code AS ship_mode_code,
    r_cr.r_reason_desc AS catalog_return_reason,
    COUNT(DISTINCT cr.cr_order_number) AS catalog_return_cnt,
    SUM(cr.cr_net_loss) AS total_catalog_net_loss,
    SUM(ws.ws_net_profit) AS total_web_profit,
    CASE WHEN SUM(ws.ws_net_profit) > 0 THEN 'PROFIT' ELSE 'LOSS' END AS profit_indicator,
    ad.avg_discount,
    RANK() OVER (ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
FROM
    catalog_returns cr
    JOIN catalog_sales cs ON cr.cr_order_number = cs.cs_order_number
    JOIN ship_mode sm1 ON cs.cs_ship_mode_sk = sm1.sm_ship_mode_sk
                      AND cr.cr_ship_mode_sk = sm1.sm_ship_mode_sk
    JOIN reason r_cr ON cr.cr_reason_sk = r_cr.r_reason_sk
    JOIN catalog_sales cs_item ON cr.cr_item_sk = cs_item.cs_item_sk
    JOIN web_sales ws ON ws.ws_ship_mode_sk = sm1.sm_ship_mode_sk
    JOIN ship_mode sm2 ON ws.ws_ship_mode_sk = sm2.sm_ship_mode_sk
    JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
    JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
    JOIN reason r_wr ON wr.wr_reason_sk = r_wr.r_reason_sk
    CROSS JOIN avg_discount_cte ad
WHERE
    sm1.sm_code IN (SELECT val FROM union_vals WHERE val LIKE 'A%')
GROUP BY
    sm1.sm_code,
    r_cr.r_reason_desc,
    ad.avg_discount
ORDER BY
    total_web_profit DESC
LIMIT 100
