WITH sales_returns AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_order_number,
        cs.cs_net_paid,
        cs.cs_warehouse_sk,
        cs.cs_item_sk,
        cr.cr_return_amount,
        cr.cr_return_quantity,
        cr.cr_reason_sk,
        r.r_reason_desc,
        w.w_warehouse_name,
        w.w_state,
        d.d_year,
        d.d_moy,
        d.d_current_year
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
        AND cr.cr_item_sk = cs.cs_item_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
)
SELECT
    sr.d_year,
    sr.w_warehouse_name,
    sr.r_reason_desc,
    COUNT(DISTINCT sr.cs_order_number) AS order_cnt,
    SUM(sr.cs_net_paid) AS total_net_paid,
    AVG(ws.ws_ext_tax) AS avg_ext_tax,
    SUM(CASE WHEN sr.cr_return_quantity > 0 THEN sr.cr_return_amount ELSE 0 END) AS total_return_amount,
    MAX(wr.wr_refunded_cash) AS max_refunded_cash
FROM sales_returns sr
JOIN web_sales ws ON ws.ws_warehouse_sk = sr.cs_warehouse_sk
JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
    AND wr.wr_item_sk = ws.ws_item_sk
    AND wr.wr_web_page_sk = wp.wp_web_page_sk
WHERE sr.d_moy = 12
  AND sr.w_state = 'CA'
  AND sr.d_current_year = 'Y'
  AND ws.ws_ext_tax > 20.00
GROUP BY sr.d_year, sr.w_warehouse_name, sr.r_reason_desc
ORDER BY total_net_paid DESC
LIMIT 100
