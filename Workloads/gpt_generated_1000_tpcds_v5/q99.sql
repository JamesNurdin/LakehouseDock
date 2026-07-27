WITH ws_summary AS (
    SELECT
        ws.ws_order_number,
        ws.ws_sold_date_sk,
        ws.ws_ship_date_sk,
        ws.ws_bill_customer_sk,
        ws.ws_ship_customer_sk,
        ws.ws_warehouse_sk,
        ws.ws_promo_sk,
        ws.ws_web_page_sk,
        ws.ws_web_site_sk,
        ws.ws_net_paid_inc_tax,
        ws.ws_quantity,
        ws.ws_sales_price,
        ws.ws_ext_discount_amt,
        ws.ws_ext_tax,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_warehouse_sk ORDER BY ws.ws_net_paid_inc_tax DESC) AS rn_warehouse_sales
    FROM web_sales ws
    WHERE ws.ws_quantity > 0
      AND ws.ws_sales_price > 10
),
return_counts AS (
    SELECT
        cr_warehouse_sk,
        COUNT(*) AS total_returns
    FROM catalog_returns
    GROUP BY cr_warehouse_sk
)
SELECT
    cr.cr_order_number,
    cr.cr_return_quantity,
    cr.cr_return_amount,
    cp.cp_department,
    w.w_warehouse_name,
    d_return.d_year AS return_year,
    c_refunded.c_customer_id AS refunded_customer_id,
    c_returning.c_customer_id AS returning_customer_id,
    ws.ws_order_number,
    ws.ws_net_paid_inc_tax,
    p.p_promo_name,
    wp.wp_url,
    ws.rn_warehouse_sales,
    RANK() OVER (PARTITION BY w.w_warehouse_id ORDER BY ws.ws_net_paid_inc_tax DESC) AS warehouse_sales_rank,
    CASE
        WHEN cr.cr_return_amount > 100 THEN 'High'
        WHEN cr.cr_return_amount > 50 THEN 'Medium'
        ELSE 'Low'
    END AS return_severity,
    rc.total_returns AS total_returns_in_warehouse
FROM catalog_returns cr
JOIN catalog_page cp
    ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN warehouse w
    ON cr.cr_warehouse_sk = w.w_warehouse_sk
JOIN date_dim d_return
    ON cr.cr_returned_date_sk = d_return.d_date_sk
JOIN customer c_refunded
    ON cr.cr_refunded_customer_sk = c_refunded.c_customer_sk
JOIN customer c_returning
    ON cr.cr_returning_customer_sk = c_returning.c_customer_sk
LEFT JOIN ws_summary ws
    ON ws.ws_warehouse_sk = w.w_warehouse_sk
    AND ws.ws_order_number = cr.cr_order_number
LEFT JOIN promotion p
    ON ws.ws_promo_sk = p.p_promo_sk
LEFT JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
LEFT JOIN web_site site
    ON ws.ws_web_site_sk = site.web_site_sk
LEFT JOIN return_counts rc
    ON rc.cr_warehouse_sk = w.w_warehouse_sk
WHERE cp.cp_type = 'Catalog'
  AND w.w_city IN ('Pleasant Valley', 'Riverside')
  AND d_return.d_year BETWEEN 2000 AND 2002
  AND c_refunded.c_preferred_cust_flag = 'Y'
  AND p.p_discount_active = 'Y'
  AND wp.wp_type = 'Content'
ORDER BY ws.ws_net_paid_inc_tax DESC
LIMIT 100
