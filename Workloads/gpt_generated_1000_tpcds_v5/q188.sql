WITH ws_detail AS (
    SELECT
        ws.ws_order_number,
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        ws.ws_bill_customer_sk,
        ws.ws_ship_mode_sk,
        ws.ws_web_site_sk,
        ws.ws_quantity,
        ws.ws_ext_sales_price,
        ws.ws_net_profit,
        ws.ws_net_paid_inc_ship_tax
    FROM web_sales ws
    JOIN date_dim d_sold
        ON ws.ws_sold_date_sk = d_sold.d_date_sk
    JOIN item i
        ON ws.ws_item_sk = i.i_item_sk
    JOIN customer c
        ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN ship_mode sm
        ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN web_site wsite
        ON ws.ws_web_site_sk = wsite.web_site_sk
    WHERE d_sold.d_year = 2001
      AND i.i_brand = 'Brand#23'
      AND sm.sm_type = 'EXPRESS'
)
SELECT
    d_sold.d_year,
    wsite.web_name,
    i.i_category,
    sm.sm_type,
    COUNT(DISTINCT ws_detail.ws_order_number) AS orders,
    SUM(ws_detail.ws_quantity) AS total_qty,
    SUM(ws_detail.ws_ext_sales_price) AS total_sales,
    AVG(ws_detail.ws_net_profit) AS avg_profit,
    CASE
        WHEN SUM(ws_detail.ws_quantity) > 1000 THEN 'HIGH_VOLUME'
        ELSE 'NORMAL_VOLUME'
    END AS volume_category
FROM ws_detail
JOIN date_dim d_sold
    ON ws_detail.ws_sold_date_sk = d_sold.d_date_sk
JOIN item i
    ON ws_detail.ws_item_sk = i.i_item_sk
JOIN ship_mode sm
    ON ws_detail.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN web_site wsite
    ON ws_detail.ws_web_site_sk = wsite.web_site_sk
JOIN inventory inv
    ON inv.inv_item_sk = i.i_item_sk
   AND inv.inv_date_sk = d_sold.d_date_sk
WHERE EXISTS (
    SELECT 1
    FROM catalog_returns cr
    WHERE cr.cr_item_sk = i.i_item_sk
      AND cr.cr_returned_date_sk = d_sold.d_date_sk
      AND cr.cr_return_amount > 50.00
)
GROUP BY d_sold.d_year, wsite.web_name, i.i_category, sm.sm_type
ORDER BY total_sales DESC
LIMIT 100
