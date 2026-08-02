WITH cr_cp AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_returned_time_sk,
        cr.cr_warehouse_sk,
        cr.cr_net_loss,
        cr.cr_order_number,
        cp.cp_catalog_page_id,
        cp.cp_department,
        cp.cp_catalog_number,
        cp.cp_catalog_page_number,
        cp.cp_description
    FROM
        catalog_returns cr
    FULL OUTER JOIN
        catalog_page cp
    ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
)
SELECT
    d.d_year,
    w1.w_warehouse_name AS sales_warehouse,
    w2.w_warehouse_name AS return_warehouse,
    ws_site.web_city,
    p.p_promo_name,
    SUM(ws.ws_net_paid) AS total_sales_net_paid,
    SUM(cr_cp.cr_net_loss) AS total_returns_net_loss,
    COUNT(DISTINCT ws.ws_order_number) AS num_orders,
    COUNT(DISTINCT cr_cp.cr_order_number) AS num_returns
FROM
    web_sales ws
JOIN date_dim d
    ON ws.ws_sold_date_sk = d.d_date_sk
JOIN time_dim t
    ON ws.ws_sold_time_sk = t.t_time_sk
JOIN customer c_bill
    ON ws.ws_bill_customer_sk = c_bill.c_customer_sk
JOIN customer_demographics cd_bill
    ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
JOIN customer c_ship
    ON ws.ws_ship_customer_sk = c_ship.c_customer_sk
JOIN customer_demographics cd_ship
    ON ws.ws_ship_cdemo_sk = cd_ship.cd_demo_sk
JOIN web_site ws_site
    ON ws.ws_web_site_sk = ws_site.web_site_sk
JOIN warehouse w1
    ON ws.ws_warehouse_sk = w1.w_warehouse_sk
JOIN promotion p
    ON ws.ws_promo_sk = p.p_promo_sk
LEFT JOIN cr_cp
    ON cr_cp.cr_returned_date_sk = d.d_date_sk
LEFT JOIN warehouse w2
    ON cr_cp.cr_warehouse_sk = w2.w_warehouse_sk
WHERE
    ws.ws_net_paid > (
        SELECT MAX(ws2.ws_net_paid)
        FROM web_sales ws2
        WHERE ws2.ws_sold_date_sk = 2451114
    )
GROUP BY
    d.d_year,
    w1.w_warehouse_name,
    w2.w_warehouse_name,
    ws_site.web_city,
    p.p_promo_name
ORDER BY
    total_sales_net_paid DESC
LIMIT 100
