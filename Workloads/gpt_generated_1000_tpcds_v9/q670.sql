WITH web_sales_metrics AS (
    SELECT
        c.c_customer_id,
        'web_sales' AS metric_type,
        SUM(ws.ws_net_paid) AS metric_value,
        CONCAT('Orders:', CAST(COUNT(DISTINCT ws.ws_order_number) AS VARCHAR), ', URLPrefix:', SUBSTRING(MIN(wp.wp_url), 1, 10)) AS detail
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE REGEXP_LIKE(p.p_promo_name, '(?i)discount|promo')
      AND wp.wp_url LIKE '%/sale%'
    GROUP BY c.c_customer_id
),
catalog_return_metrics AS (
    SELECT
        c.c_customer_id,
        'catalog_returns' AS metric_type,
        SUM(cr.cr_refunded_cash) AS metric_value,
        CONCAT('Returns:', CAST(SUM(cr.cr_return_quantity) AS VARCHAR), ', DescWord:', REGEXP_EXTRACT(MIN(cp.cp_description), '^([A-Za-z]+)', 1)) AS detail
    FROM catalog_returns cr
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE REGEXP_LIKE(cp.cp_description, '(?i)clearance')
      AND cp.cp_type LIKE 'C%'
    GROUP BY c.c_customer_id
)
SELECT
    c_customer_id,
    metric_type,
    metric_value,
    detail
FROM web_sales_metrics
UNION ALL
SELECT
    c_customer_id,
    metric_type,
    metric_value,
    detail
FROM catalog_return_metrics
ORDER BY metric_value DESC
LIMIT 100
