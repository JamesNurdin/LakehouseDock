WITH item_sales AS (
    SELECT
        i.i_item_sk,
        i.i_brand_id,
        i.i_brand,
        SUM(cs.cs_ext_sales_price) AS catalog_sales_amount,
        SUM(ws.ws_ext_sales_price) AS web_sales_amount,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_orders,
        COUNT(DISTINCT ws.ws_order_number) AS web_orders
    FROM
        catalog_sales cs
        JOIN item i ON cs.cs_item_sk = i.i_item_sk
        JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
        JOIN customer c_bill ON cs.cs_bill_customer_sk = c_bill.c_customer_sk
        JOIN customer c_ws_bill ON ws.ws_bill_customer_sk = c_ws_bill.c_customer_sk
        JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
        JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
        JOIN ship_mode sm_ws ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
    WHERE
        cc.cc_division_name IN ('able', 'anti')
        AND i.i_brand_id IN (6008007, 1002001)
        AND sm.sm_type = 'AIR'
        AND c_bill.c_salutation = 'Mr.'
        AND cs.cs_quantity > 5
    GROUP BY
        i.i_item_sk,
        i.i_brand_id,
        i.i_brand
)
SELECT
    isub.i_item_sk,
    isub.i_brand_id,
    isub.i_brand,
    isub.catalog_sales_amount,
    isub.web_sales_amount,
    (isub.catalog_sales_amount + isub.web_sales_amount) AS total_sales,
    RANK() OVER (PARTITION BY isub.i_brand_id ORDER BY (isub.catalog_sales_amount + isub.web_sales_amount) DESC) AS sales_rank_by_brand,
    CASE
        WHEN (isub.catalog_sales_amount + isub.web_sales_amount) > (
            SELECT AVG(catalog_sales_amount + web_sales_amount) FROM item_sales
        ) THEN 'Above Avg'
        ELSE 'Below Avg'
    END AS sales_category
FROM
    item_sales isub
ORDER BY
    total_sales DESC
LIMIT 100
