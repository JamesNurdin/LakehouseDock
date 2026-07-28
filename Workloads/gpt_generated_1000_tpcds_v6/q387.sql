WITH date_filter AS (
    SELECT d_date_sk
    FROM date_dim
    WHERE d_year = 2001
)
SELECT
    c.c_customer_id,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
    SUM(cs.cs_net_paid) AS total_catalog_sales,
    SUM(ws.ws_net_paid) AS total_web_sales,
    COALESCE(SUM(sr.sr_return_amt), 0) AS total_store_returns,
    COALESCE(SUM(wr.wr_return_amt), 0) AS total_web_returns,
    SUM(CASE WHEN rc.r_reason_desc = 'Damaged' THEN 1 ELSE 0 END) AS damaged_catalog_returns,
    CASE
        WHEN SUM(cs.cs_net_paid) + SUM(ws.ws_net_paid) - COALESCE(SUM(sr.sr_return_amt), 0) - COALESCE(SUM(wr.wr_return_amt), 0) > 10000
        THEN 'High'
        ELSE 'Normal'
    END AS customer_segment
FROM catalog_sales cs
JOIN catalog_returns cr
    ON cr.cr_order_number = cs.cs_order_number
   AND cr.cr_item_sk = cs.cs_item_sk
JOIN reason rc
    ON cr.cr_reason_sk = rc.r_reason_sk
JOIN customer c
    ON cs.cs_bill_customer_sk = c.c_customer_sk
JOIN date_dim d_cs_sold
    ON cs.cs_sold_date_sk = d_cs_sold.d_date_sk
   AND d_cs_sold.d_year = 2001
LEFT JOIN store_returns sr
    ON sr.sr_customer_sk = c.c_customer_sk
   AND sr.sr_returned_date_sk = d_cs_sold.d_date_sk
JOIN web_sales ws
    ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN date_dim d_ws_sold
    ON ws.ws_sold_date_sk = d_ws_sold.d_date_sk
JOIN web_site we
    ON ws.ws_web_site_sk = we.web_site_sk
LEFT JOIN web_returns wr
    ON wr.wr_order_number = ws.ws_order_number
   AND wr.wr_item_sk = ws.ws_item_sk
   AND wr.wr_returned_date_sk = d_ws_sold.d_date_sk
LEFT JOIN reason rw
    ON wr.wr_reason_sk = rw.r_reason_sk
WHERE
    we.web_country = 'United States'
    AND c.c_preferred_cust_flag = 'Y'
    AND NOT EXISTS (
        SELECT 1
        FROM catalog_returns cr2
        JOIN reason r2 ON cr2.cr_reason_sk = r2.r_reason_sk
        WHERE cr2.cr_refunded_customer_sk = c.c_customer_sk
          AND r2.r_reason_desc = 'Damaged'
    )
GROUP BY
    c.c_customer_id
ORDER BY
    total_catalog_sales DESC
LIMIT 100
