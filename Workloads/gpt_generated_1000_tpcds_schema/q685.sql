WITH sales_by_order AS (
    SELECT
        ws_warehouse_sk,
        ws_web_site_sk,
        ws_promo_sk,
        ws_order_number,
        SUM(ws_net_paid) AS order_sales,
        SUM(ws_quantity) AS order_qty,
        AVG(ws_ext_discount_amt) AS avg_discount
    FROM web_sales
    GROUP BY ws_warehouse_sk, ws_web_site_sk, ws_promo_sk, ws_order_number
),
intersect_orders AS (
    SELECT ws_order_number FROM (
        SELECT ws_order_number FROM web_sales WHERE ws_ext_wholesale_cost > 2000
    )
    INTERSECT
    SELECT ws_order_number FROM web_sales WHERE ws_list_price BETWEEN 50 AND 100
)
SELECT
    w.w_warehouse_name,
    p.p_promo_name,
    CASE WHEN p.p_discount_active = 'Y' THEN 'Active' ELSE 'Inactive' END AS promo_status,
    SUM(sa.order_sales) AS total_sales,
    COUNT(DISTINCT sa.ws_order_number) AS distinct_orders,
    MIN(sa.avg_discount) AS min_avg_discount,
    (SELECT AVG(ws_ext_discount_amt) FROM web_sales) AS overall_avg_discount
FROM sales_by_order sa
FULL OUTER JOIN promotion p
    ON sa.ws_promo_sk = p.p_promo_sk
JOIN warehouse w
    ON sa.ws_warehouse_sk = w.w_warehouse_sk
JOIN web_site ws
    ON sa.ws_web_site_sk = ws.web_site_sk
WHERE
    (p.p_channel_press = 'N' OR p.p_channel_press IS NULL)
    AND (p.p_response_target = 1 OR p.p_response_target IS NULL)
    AND (w.w_zip = '74136' OR w.w_zip IS NULL)
    AND (ws.web_rec_end_date = DATE '2001-08-15' OR ws.web_rec_end_date IS NULL)
    AND (ws.web_company_name = 'ese' OR ws.web_company_name IS NULL)
    AND sa.ws_order_number IN (SELECT ws_order_number FROM intersect_orders)
GROUP BY
    w.w_warehouse_name,
    p.p_promo_name,
    CASE WHEN p.p_discount_active = 'Y' THEN 'Active' ELSE 'Inactive' END
ORDER BY total_sales DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
