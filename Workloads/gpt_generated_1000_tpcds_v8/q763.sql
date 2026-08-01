WITH
    base_chain AS (
        SELECT
            t.t_time_sk,
            t.t_hour,
            t.t_am_pm,
            ss.ss_quantity,
            ss.ss_net_paid,
            c.c_customer_sk,
            c.c_first_name,
            c.c_last_name,
            cd.cd_gender,
            cd.cd_purchase_estimate,
            cp.cp_department,
            cp.cp_type,
            cs.cs_ext_sales_price,
            ws.ws_ext_sales_price,
            wp.wp_type,
            wsite.web_city,
            wsite.web_gmt_offset
        FROM time_dim t
        JOIN store_sales ss ON ss.ss_sold_time_sk = t.t_time_sk
        JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
        JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
        JOIN catalog_sales cs ON cs.cs_sold_time_sk = t.t_time_sk
            AND cs.cs_bill_customer_sk = c.c_customer_sk
            AND cs.cs_bill_cdemo_sk = cd.cd_demo_sk
        JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
        JOIN web_sales ws ON ws.ws_sold_time_sk = t.t_time_sk
            AND ws.ws_bill_customer_sk = c.c_customer_sk
            AND ws.ws_bill_cdemo_sk = cd.cd_demo_sk
        JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
        JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
        WHERE
            t.t_hour BETWEEN 9 AND 11
            AND t.t_am_pm = 'AM'
            AND cd.cd_gender = 'F'
            AND cd.cd_purchase_estimate >= 3000
            AND cp.cp_department = 'Electronics'
            AND wsite.web_city = 'Pleasant Valley'
            AND wp.wp_type = 'CONTENT'
            AND cs.cs_catalog_page_sk IN (
                SELECT cp2.cp_catalog_page_sk
                FROM catalog_page cp2
                WHERE cp2.cp_type = 'PROMO'
            )
    ),
    catalog_summary AS (
        SELECT
            cp_department AS category,
            SUM(cs_ext_sales_price) AS total_sales,
            COUNT(*) AS order_cnt,
            AVG(cs_ext_sales_price) AS avg_price
        FROM base_chain
        GROUP BY cp_department
    ),
    web_summary AS (
        SELECT
            web_city AS category,
            SUM(ws_ext_sales_price) AS total_sales,
            COUNT(*) AS order_cnt,
            AVG(ws_ext_sales_price) AS avg_price
        FROM base_chain
        GROUP BY web_city
    ),
    union_summary AS (
        SELECT category, total_sales, order_cnt, avg_price FROM catalog_summary
        UNION
        SELECT category, total_sales, order_cnt, avg_price FROM web_summary
    ),
    except_summary AS (
        SELECT category FROM union_summary
        EXCEPT
        SELECT cp_department FROM catalog_page WHERE cp_type = 'ARCHIVE'
    ),
    full_join_summary AS (
        SELECT
            ca.category AS cat,
            ca.total_sales AS cat_sales,
            ws.total_sales AS web_sales
        FROM catalog_summary ca
        FULL OUTER JOIN web_summary ws
            ON ca.category = ws.category
    )
SELECT
    f.cat,
    COALESCE(f.cat_sales, 0) AS catalog_sales,
    COALESCE(f.web_sales, 0) AS web_sales,
    CASE WHEN f.cat IN (SELECT category FROM except_summary) THEN 'Keep' ELSE 'Removed' END AS status
FROM full_join_summary f
WHERE f.cat IS NOT NULL
ORDER BY catalog_sales DESC, web_sales DESC
LIMIT 50
