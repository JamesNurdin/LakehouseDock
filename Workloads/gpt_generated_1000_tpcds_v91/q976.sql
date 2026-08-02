WITH catalog_fact_agg AS (
    SELECT
        c.c_customer_sk,
        c.c_customer_id,
        cd.cd_gender,
        ca.ca_state,
        cp.cp_department,
        sm.sm_type,
        w.w_warehouse_name,
        SUM(cs.cs_net_profit) AS total_catalog_profit,
        SUM(cs.cs_ext_sales_price) AS total_catalog_sales,
        COUNT(DISTINCT cs.cs_order_number) AS num_catalog_orders,
        SUM(CASE WHEN cr.cr_return_quantity > 0 THEN cr.cr_net_loss ELSE 0 END) AS total_return_loss,
        COUNT(DISTINCT cr.cr_order_number) AS num_returns
    FROM
        catalog_sales cs
        JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
        JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
        JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
        JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
        JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
        JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
        LEFT JOIN catalog_returns cr
            ON cs.cs_order_number = cr.cr_order_number
            AND cs.cs_item_sk = cr.cr_item_sk
    WHERE
        cp.cp_catalog_number BETWEEN 2 AND 5
        AND ca.ca_country = 'United States'
        AND cd.cd_credit_rating = 'Good'
    GROUP BY
        c.c_customer_sk,
        c.c_customer_id,
        cd.cd_gender,
        ca.ca_state,
        cp.cp_department,
        sm.sm_type,
        w.w_warehouse_name
),
store_fact_agg AS (
    SELECT
        c.c_customer_sk,
        s.s_store_name,
        SUM(ss.ss_net_profit) AS total_store_profit,
        SUM(ss.ss_ext_sales_price) AS total_store_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS num_store_orders
    FROM
        store_sales ss
        JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
        JOIN store s ON ss.ss_store_sk = s.s_store_sk
    WHERE
        s.s_state = 'CA'
        AND ss.ss_quantity > 0
    GROUP BY
        c.c_customer_sk,
        s.s_store_name
),
web_returns_agg AS (
    SELECT
        c.c_customer_sk,
        SUM(wr.wr_net_loss) AS total_web_return_loss,
        COUNT(*) AS num_web_returns,
        wp.wp_url
    FROM
        web_returns wr
        JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
        JOIN customer c ON wr.wr_refunded_customer_sk = c.c_customer_sk
    WHERE
        wp.wp_url LIKE 'http%'
        AND c.c_preferred_cust_flag = 'Y'
    GROUP BY
        c.c_customer_sk,
        wp.wp_url
)
SELECT
    result.c_customer_id,
    result.source,
    result.total_profit,
    result.total_sales,
    result.profit_category,
    result.store_profit,
    result.store_sales,
    COALESCE(wr.total_web_return_loss, 0) AS web_return_loss,
    COALESCE(wr.num_web_returns, 0) AS web_return_cnt,
    (
        SELECT COUNT(*)
        FROM catalog_returns cr2
        WHERE cr2.cr_refunded_customer_sk = result.c_customer_sk
    ) AS total_catalog_return_events,
    CASE
        WHEN result.total_profit > 2000 THEN 'High'
        WHEN result.total_profit > 0 THEN 'Medium'
        ELSE 'Low'
    END AS overall_category
FROM (
    SELECT
        c.c_customer_id,
        c.c_customer_sk,
        'catalog' AS source,
        ca.total_catalog_profit AS total_profit,
        ca.total_catalog_sales AS total_sales,
        CASE WHEN ca.total_catalog_profit > 0 THEN 'Profit' ELSE 'Loss' END AS profit_category,
        NULL AS store_profit,
        NULL AS store_sales,
        ca.total_return_loss AS placeholder_web_return_loss,
        ca.num_returns AS placeholder_web_return_cnt
    FROM
        catalog_fact_agg ca
        JOIN customer c ON ca.c_customer_sk = c.c_customer_sk

    UNION ALL

    SELECT
        c.c_customer_id,
        c.c_customer_sk,
        'store' AS source,
        sf.total_store_profit AS total_profit,
        sf.total_store_sales AS total_sales,
        CASE WHEN sf.total_store_profit > 0 THEN 'Profit' ELSE 'Loss' END AS profit_category,
        sf.total_store_profit AS store_profit,
        sf.total_store_sales AS store_sales,
        NULL AS placeholder_web_return_loss,
        sf.num_store_orders AS placeholder_web_return_cnt
    FROM
        store_fact_agg sf
        JOIN customer c ON sf.c_customer_sk = c.c_customer_sk
) AS result
LEFT JOIN web_returns_agg wr ON wr.c_customer_sk = result.c_customer_sk
WHERE
    NOT EXISTS (
        SELECT 1
        FROM catalog_returns cr_not
        WHERE cr_not.cr_refunded_customer_sk = result.c_customer_sk
          AND cr_not.cr_return_quantity > 0
    )
    AND result.profit_category = 'Profit'
ORDER BY result.total_profit DESC
LIMIT 50
