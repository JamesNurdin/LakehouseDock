WITH
    /* Aggregate sales per item */
    sales_agg AS (
        SELECT
            cs.cs_item_sk,
            SUM(cs.cs_ext_sales_price)      AS total_sales,
            SUM(cs.cs_quantity)             AS total_quantity,
            COUNT(DISTINCT cs.cs_order_number) AS order_cnt
        FROM
            catalog_sales cs
            JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
        WHERE
            d.d_year = 2001
            AND cs.cs_wholesale_cost > 10
        GROUP BY
            cs.cs_item_sk
    ),
    /* Aggregate returns per item */
    returns_agg AS (
        SELECT
            cr.cr_item_sk,
            SUM(cr.cr_return_amount)          AS total_returns,
            SUM(cr.cr_return_quantity)        AS total_return_qty,
            COUNT(DISTINCT cr.cr_order_number) AS return_cnt
        FROM
            catalog_returns cr
            JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
        WHERE
            d.d_year = 2001
        GROUP BY
            cr.cr_item_sk
    ),
    /* Distinct item keys from sales and returns */
    union_items AS (
        SELECT cs_item_sk AS item_sk FROM sales_agg
        UNION
        SELECT cr_item_sk        FROM returns_agg
    ),
    /* Customers that bought both online and in catalog */
    intersect_customers AS (
        SELECT ws.ws_bill_customer_sk AS cust_sk FROM web_sales ws
        INTERSECT
        SELECT cs.cs_bill_customer_sk       FROM catalog_sales cs
    ),
    /* Customers who purchased but never had a return */
    except_customers AS (
        SELECT cs.cs_bill_customer_sk AS cust_sk FROM catalog_sales cs
        EXCEPT
        SELECT cr.cr_refunded_customer_sk FROM catalog_returns cr
    )
SELECT
    d.d_year,
    cc.cc_state,
    ca.ca_state,
    sm.sm_type,
    SUM(sa.total_sales)      AS sum_sales,
    SUM(ra.total_returns)    AS sum_returns,
    COUNT(DISTINCT ic.cust_sk)   AS distinct_intersect_customers,
    COUNT(DISTINCT ec.cust_sk)   AS distinct_non_returning_customers,
    COUNT(DISTINCT ui.item_sk)   AS distinct_items
FROM
    sales_agg sa
    JOIN catalog_sales cs               ON cs.cs_item_sk = sa.cs_item_sk
    JOIN catalog_returns cr             ON cr.cr_order_number = cs.cs_order_number
    JOIN catalog_page cp                ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN call_center cc                 ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm                   ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w                    ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN customer c                     ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca            ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd       ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd      ON c.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN date_dim d                     ON cs.cs_sold_date_sk = d.d_date_sk
    FULL OUTER JOIN store s             ON s.s_closed_date_sk = d.d_date_sk
    LEFT JOIN web_sales ws              ON ws.ws_bill_customer_sk = c.c_customer_sk
    LEFT JOIN web_page wp               ON ws.ws_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN web_site we                ON ws.ws_web_site_sk = we.web_site_sk
    LEFT JOIN returns_agg ra            ON ra.cr_item_sk = sa.cs_item_sk
    LEFT JOIN intersect_customers ic    ON ic.cust_sk = c.c_customer_sk
    LEFT JOIN except_customers ec       ON ec.cust_sk = c.c_customer_sk
    LEFT JOIN union_items ui            ON ui.item_sk = sa.cs_item_sk
WHERE
    cc.cc_sq_ft > 500000000                 -- filter 1: large call centres
    AND ca.ca_zip = '57783'                  -- filter 2: specific ZIP code
    AND sm.sm_type = 'AIR'                   -- filter 3: air shipment mode
    AND d.d_current_year = 'Y'               -- filter 4: current year flag
GROUP BY
    d.d_year,
    cc.cc_state,
    ca.ca_state,
    sm.sm_type
ORDER BY
    sum_sales DESC
OFFSET 0
LIMIT 100
