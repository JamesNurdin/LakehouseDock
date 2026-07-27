WITH sales_agg AS (
    SELECT
        i.i_category AS i_category,
        sm.sm_type AS sm_type,
        SUM(cs.cs_ext_sales_price) AS catalog_sales,
        SUM(ws.ws_ext_sales_price) AS web_sales,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_orders,
        COUNT(DISTINCT ws.ws_order_number) AS web_orders,
        SUM(cs.cs_ext_sales_price) + SUM(ws.ws_ext_sales_price) AS total_sales
    FROM
        catalog_sales cs
        JOIN customer c
            ON cs.cs_bill_customer_sk = c.c_customer_sk
        JOIN customer_demographics cd
            ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
        JOIN call_center cc
            ON cs.cs_call_center_sk = cc.cc_call_center_sk
        JOIN catalog_page cp
            ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
        JOIN ship_mode sm
            ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
        JOIN item i
            ON cs.cs_item_sk = i.i_item_sk
        JOIN web_sales ws
            ON ws.ws_item_sk = i.i_item_sk
            AND ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE
        sm.sm_code = 'AIR'
        AND i.i_wholesale_cost > 10
        AND cd.cd_marital_status = 'M'
        AND cc.cc_state = 'CA'
        AND i.i_rec_start_date >= DATE '2000-01-01'
    GROUP BY
        ROLLUP(i.i_category, sm.sm_type)
)
SELECT
    i_category,
    sm_type,
    catalog_sales,
    web_sales,
    total_sales,
    ROW_NUMBER() OVER (PARTITION BY i_category ORDER BY total_sales DESC) AS sales_rank
FROM sales_agg
ORDER BY i_category, sm_type
LIMIT 100
