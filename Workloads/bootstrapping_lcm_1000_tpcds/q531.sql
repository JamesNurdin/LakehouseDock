SELECT
    d_ret.d_year AS return_year,
    s.s_division_id,
    cr.cr_reason_sk,
    CASE WHEN cr.cr_return_quantity > 0 THEN 'RETURN' ELSE 'NO_RETURN' END AS return_flag,
    SUM(cs.cs_net_paid) AS total_catalog_sales,
    SUM(ws.ws_net_paid) AS total_web_sales,
    SUM(cr.cr_net_loss) AS total_return_loss,
    COUNT(DISTINCT cs.cs_order_number) AS catalog_order_cnt,
    COUNT(DISTINCT ws.ws_order_number) AS web_order_cnt,
    SUM(cs.cs_net_profit) AS catalog_net_profit,
    SUM(ws.ws_net_profit) AS web_net_profit,
    (SUM(cs.cs_net_profit) + SUM(ws.ws_net_profit)) / NULLIF(SUM(cs.cs_net_paid) + SUM(ws.ws_net_paid), 0) AS overall_profit_margin,
    SUM(cr.cr_return_quantity) AS total_return_qty,
    SUM(cs.cs_quantity) AS total_sold_qty,
    (SUM(cr.cr_return_quantity) * 100.0) / NULLIF(SUM(cs.cs_quantity), 0) AS return_qty_percentage
FROM catalog_returns cr
JOIN catalog_sales cs
    ON cr.cr_item_sk = cs.cs_item_sk
   AND cr.cr_order_number = cs.cs_order_number
JOIN date_dim d_ret
    ON cr.cr_returned_date_sk = d_ret.d_date_sk
JOIN date_dim d_sales
    ON cs.cs_sold_date_sk = d_sales.d_date_sk
JOIN web_sales ws
    ON ws.ws_sold_date_sk = d_sales.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_ret.d_date_sk
GROUP BY
    d_ret.d_year,
    s.s_division_id,
    cr.cr_reason_sk,
    CASE WHEN cr.cr_return_quantity > 0 THEN 'RETURN' ELSE 'NO_RETURN' END
ORDER BY total_catalog_sales DESC
LIMIT 100
