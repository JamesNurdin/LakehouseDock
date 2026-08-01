WITH catalog_branch AS (
    SELECT
        i.i_category AS category,
        i.i_class AS class,
        r.r_reason_desc AS reason_desc,
        SUM(cs.cs_net_paid) AS total_sales,
        SUM(cs.cs_ext_discount_amt) AS total_discount,
        COUNT(DISTINCT cs.cs_order_number) AS order_cnt,
        SUM(COALESCE(cr.cr_return_amount, 0)) AS total_return_amount,
        COUNT(DISTINCT cr.cr_order_number) AS return_cnt,
        CASE WHEN EXISTS (
            SELECT 1
            FROM store_sales ss
            WHERE ss.ss_item_sk = i.i_item_sk
              AND ss.ss_quantity > 0
        ) THEN 1 ELSE 0 END AS has_store_sales_flag
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    LEFT JOIN catalog_returns cr ON cs.cs_order_number = cr.cr_order_number
    LEFT JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE
        cs.cs_quantity > 1
        AND cs.cs_ext_sales_price > 1000
        AND i.i_category = 'Electronics'
        AND cc.cc_state = 'CA'
        AND cd.cd_gender = 'M'
        AND hd.hd_income_band_sk = 5
        AND c.c_birth_country = 'United States'
    GROUP BY
        i.i_category,
        i.i_class,
        r.r_reason_desc,
        i.i_item_sk
),
web_branch AS (
    SELECT
        i.i_category AS category,
        i.i_class AS class,
        r.r_reason_desc AS reason_desc,
        SUM(ws.ws_net_paid) AS total_sales,
        SUM(ws.ws_ext_discount_amt) AS total_discount,
        COUNT(DISTINCT ws.ws_order_number) AS order_cnt,
        SUM(COALESCE(wr.wr_return_amt, 0)) AS total_return_amount,
        COUNT(DISTINCT wr.wr_order_number) AS return_cnt,
        CASE WHEN EXISTS (
            SELECT 1
            FROM store_sales ss
            WHERE ss.ss_item_sk = i.i_item_sk
              AND ss.ss_quantity > 0
        ) THEN 1 ELSE 0 END AS has_store_sales_flag
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN web_returns wr ON ws.ws_order_number = wr.wr_order_number
    LEFT JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    WHERE
        ws.ws_quantity > 1
        AND ws.ws_ext_sales_price > 1000
        AND i.i_category = 'Electronics'
        AND wp.wp_type = 'home'
        AND cd.cd_gender = 'M'
        AND hd.hd_vehicle_count >= 2
        AND c.c_birth_country = 'United States'
        AND wp.wp_url LIKE '%example%'
    GROUP BY
        i.i_category,
        i.i_class,
        r.r_reason_desc,
        i.i_item_sk
)
SELECT
    category,
    class,
    reason_desc,
    SUM(total_sales) AS total_sales,
    SUM(total_discount) AS total_discount,
    SUM(total_return_amount) AS total_return_amount,
    SUM(order_cnt) AS total_orders,
    SUM(return_cnt) AS total_returns,
    MAX(has_store_sales_flag) AS store_sales_present_flag
FROM (
    SELECT * FROM catalog_branch
    UNION ALL
    SELECT * FROM web_branch
) AS combined
GROUP BY
    category,
    class,
    reason_desc
ORDER BY
    total_sales DESC
LIMIT 100
