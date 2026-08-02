WITH
    returns_agg AS (
        SELECT
            cr.cr_order_number AS order_number,
            SUM(cr.cr_return_amount) AS total_return_amount,
            COUNT(*) AS return_cnt,
            cp.cp_department AS department,
            sm.sm_carrier AS carrier,
            CASE WHEN SUM(cr.cr_return_amount) > 500 THEN 'High' ELSE 'Low' END AS return_category
        FROM catalog_returns cr
        JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
        JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
        JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
        WHERE cp.cp_catalog_number IN (3, 6, 16)
          AND cp.cp_department IN (
                SELECT cp2.cp_department
                FROM catalog_page cp2
                WHERE cp2.cp_type = 'A'
          )
        GROUP BY cr.cr_order_number, cp.cp_department, sm.sm_carrier
    ),
    sales_agg AS (
        SELECT
            ws.ws_order_number AS order_number,
            SUM(ws.ws_net_paid) AS total_net_paid,
            COUNT(*) AS sales_cnt,
            sm.sm_carrier AS carrier,
            CASE WHEN SUM(ws.ws_net_paid) > 500 THEN 'High' ELSE 'Low' END AS sales_category
        FROM web_sales ws
        JOIN web_site ws_site ON ws.ws_web_site_sk = ws_site.web_site_sk
        JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
        JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
        WHERE ws.ws_sold_date_sk BETWEEN 2450000 AND 2450100
        GROUP BY ws.ws_order_number, sm.sm_carrier
    )
SELECT
    combined.order_number,
    combined.amount,
    combined.source,
    combined.carrier,
    CASE WHEN combined.amount > 1000 THEN 'Very High' ELSE combined.amount_category END AS amount_category,
    (
        SELECT AVG(ra.total_return_amount)
        FROM returns_agg ra
        WHERE ra.carrier = combined.carrier
    ) AS avg_return_amount_by_carrier
FROM (
    SELECT
        order_number,
        total_return_amount AS amount,
        'Return' AS source,
        carrier,
        return_category AS amount_category
    FROM returns_agg
    UNION ALL
    SELECT
        order_number,
        total_net_paid AS amount,
        'Sale' AS source,
        carrier,
        sales_category AS amount_category
    FROM sales_agg
) AS combined
WHERE NOT EXISTS (
    SELECT 1
    FROM catalog_returns cr_check
    WHERE cr_check.cr_order_number = combined.order_number
      AND cr_check.cr_return_amount > combined.amount
)
LIMIT 100
