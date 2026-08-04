WITH intersect_orders AS (
    SELECT cr_order_number AS order_number FROM catalog_returns
    INTERSECT
    SELECT ws_order_number FROM web_sales
)
SELECT
    d_shared.d_year,
    w_shared.w_warehouse_name,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    COUNT(DISTINCT cr.cr_order_number) AS distinct_return_orders,
    COUNT(DISTINCT ws.ws_order_number) AS distinct_sales_orders,
    AVG(lr.discount_ratio) AS avg_discount_ratio
FROM intersect_orders io
JOIN catalog_returns cr
    ON io.order_number = cr.cr_order_number
JOIN date_dim d_shared
    ON cr.cr_returned_date_sk = d_shared.d_date_sk
JOIN customer_address ca_refunded
    ON cr.cr_refunded_addr_sk = ca_refunded.ca_address_sk
JOIN customer_address ca_returning
    ON cr.cr_returning_addr_sk = ca_returning.ca_address_sk
JOIN warehouse w_shared
    ON cr.cr_warehouse_sk = w_shared.w_warehouse_sk
JOIN web_sales ws
    ON io.order_number = ws.ws_order_number
    AND ws.ws_sold_date_sk = d_shared.d_date_sk
JOIN customer_address ca_bill
    ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
JOIN customer_address ca_ship
    ON ws.ws_ship_addr_sk = ca_ship.ca_address_sk
JOIN web_site ws_site
    ON ws.ws_web_site_sk = ws_site.web_site_sk
JOIN warehouse w_ws
    ON ws.ws_warehouse_sk = w_ws.w_warehouse_sk
JOIN date_dim d_ship
    ON ws.ws_ship_date_sk = d_ship.d_date_sk
JOIN date_dim d_open
    ON ws_site.web_open_date_sk = d_open.d_date_sk
JOIN date_dim d_close
    ON ws_site.web_close_date_sk = d_close.d_date_sk
LEFT JOIN LATERAL (
    SELECT CASE WHEN ws.ws_ext_sales_price = 0 THEN 0
                ELSE ws.ws_ext_discount_amt / ws.ws_ext_sales_price
           END AS discount_ratio
) AS lr ON TRUE
WHERE d_shared.d_year = 2001
  AND w_shared.w_country = 'United States'
  AND ws_site.web_class = 'Unknown'
GROUP BY d_shared.d_year, w_shared.w_warehouse_name
HAVING SUM(ws.ws_ext_sales_price) > 100000
ORDER BY total_sales DESC
LIMIT 100
