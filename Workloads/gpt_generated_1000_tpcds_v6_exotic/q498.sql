WITH recent_dates AS (
    SELECT d_date_sk, d_date
    FROM date_dim
    WHERE d_year = 2001
)
SELECT
    'Return' AS record_type,
    d.d_date,
    w.w_state,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_net_loss) AS total_net_loss,
    CASE WHEN SUM(cr.cr_return_amount) > 1500 THEN 'High' ELSE 'Low' END AS amount_category
FROM catalog_returns cr
JOIN recent_dates d ON cr.cr_returned_date_sk = d.d_date_sk
JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
WHERE cr.cr_catalog_page_sk IN (
    SELECT DISTINCT cr2.cr_catalog_page_sk
    FROM catalog_returns cr2
    WHERE cr2.cr_return_amt_inc_tax > 1500
)
GROUP BY d.d_date, w.w_state
HAVING SUM(cr.cr_return_amount) > 100

UNION ALL

SELECT
    'WebSale' AS record_type,
    d.d_date,
    w.w_state,
    SUM(ws.ws_ext_sales_price) AS total_return_amount,
    SUM(ws.ws_net_profit) AS total_net_loss,
    CASE WHEN SUM(ws.ws_ext_sales_price) > 1500 THEN 'High' ELSE 'Low' END AS amount_category
FROM web_sales ws
JOIN recent_dates d ON ws.ws_sold_date_sk = d.d_date_sk
JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
WHERE ws.ws_ship_mode_sk IN (
    SELECT DISTINCT cr3.cr_ship_mode_sk
    FROM catalog_returns cr3
    WHERE cr3.cr_return_amt_inc_tax > 1500
)
GROUP BY d.d_date, w.w_state
HAVING SUM(ws.ws_ext_sales_price) > 100

ORDER BY record_type, d_date, w_state
