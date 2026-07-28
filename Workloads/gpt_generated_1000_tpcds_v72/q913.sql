WITH catalog_sales_data AS (
    SELECT DISTINCT
        cs.cs_bill_customer_sk AS customer_sk,
        cs.cs_item_sk AS item_sk,
        cs.cs_ext_sales_price AS sales_amount,
        cs.cs_order_number AS order_number,
        i.i_product_name AS product_name,
        cp.cp_department AS department,
        sm.sm_carrier AS carrier,
        p.p_promo_name AS promo_name
    FROM catalog_sales cs
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    LEFT JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE i.i_rec_start_date >= DATE '2001-01-01'
      AND i.i_rec_start_date < DATE '2002-01-01'
      AND cp.cp_department = 'Home'
),
web_sales_data AS (
    SELECT DISTINCT
        ws.ws_bill_customer_sk AS customer_sk,
        ws.ws_item_sk AS item_sk,
        ws.ws_ext_sales_price AS sales_amount,
        ws.ws_order_number AS order_number,
        i.i_product_name AS product_name,
        sm.sm_carrier AS carrier,
        p.p_promo_name AS promo_name
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    LEFT JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE i.i_rec_start_date >= DATE '2001-01-01'
      AND i.i_rec_start_date < DATE '2002-01-01'
      AND sm.sm_carrier = 'ORIENTAL'
)
SELECT
    customer_sk,
    item_sk,
    product_name,
    carrier,
    promo_name,
    SUM(sales_amount) AS total_sales,
    COUNT(DISTINCT order_number) AS orders
FROM (
    SELECT
        customer_sk,
        item_sk,
        product_name,
        sales_amount,
        order_number,
        carrier,
        promo_name
    FROM catalog_sales_data
    UNION ALL
    SELECT
        customer_sk,
        item_sk,
        product_name,
        sales_amount,
        order_number,
        carrier,
        promo_name
    FROM web_sales_data
) combined
GROUP BY
    customer_sk,
    item_sk,
    product_name,
    carrier,
    promo_name
ORDER BY total_sales DESC
LIMIT 100
