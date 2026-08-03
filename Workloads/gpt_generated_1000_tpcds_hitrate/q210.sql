WITH avg_return AS (
        SELECT avg(cr_return_amount) AS avg_ret
        FROM catalog_returns
    ),
    avg_sales AS (
        SELECT avg(ws_net_paid_inc_ship) AS avg_sales
        FROM web_sales
    ),
    returns_by_warehouse AS (
        SELECT
            w.w_warehouse_id,
            'Return' AS metric_type,
            SUM(cr.cr_return_amount) AS total_amount,
            CASE WHEN SUM(cr.cr_return_amount) > (SELECT avg_ret FROM avg_return)
                THEN 'Above'
                ELSE 'Below'
            END AS amount_category
        FROM catalog_returns cr
        JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
        WHERE w.w_state = 'CA'
        GROUP BY w.w_warehouse_id
    ),
    sales_by_warehouse AS (
        SELECT
            w.w_warehouse_id,
            'Sales' AS metric_type,
            SUM(ws.ws_net_paid_inc_ship) AS total_amount,
            CASE WHEN SUM(ws.ws_net_paid_inc_ship) > (SELECT avg_sales FROM avg_sales)
                THEN 'Above'
                ELSE 'Below'
            END AS amount_category
        FROM web_sales ws
        JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
        JOIN web_site s ON ws.ws_web_site_sk = s.web_site_sk
        WHERE w.w_state = 'CA'
          AND s.web_city = 'San Francisco'
          AND EXISTS (
                SELECT 1
                FROM promotion p
                WHERE p.p_promo_sk = ws.ws_promo_sk
                  AND p.p_discount_active = 'Y'
          )
        GROUP BY w.w_warehouse_id
    )
SELECT w_warehouse_id,
       metric_type,
       total_amount,
       amount_category
FROM returns_by_warehouse
UNION ALL
SELECT w_warehouse_id,
       metric_type,
       total_amount,
       amount_category
FROM sales_by_warehouse
ORDER BY w_warehouse_id,
         metric_type
LIMIT 100
