WITH combined_sales AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        cc.cc_call_center_sk,
        cc.cc_name AS call_center_name,
        w.w_warehouse_sk,
        w.w_warehouse_name AS warehouse_name,
        CAST(NULL AS varchar) AS web_site_name,
        cs.cs_ext_sales_price AS sales_price,
        cs.cs_ext_discount_amt AS discount_amt,
        cs.cs_order_number AS order_number,
        cs.cs_bill_customer_sk AS customer_sk
    FROM catalog_sales cs
    JOIN date_dim d
        ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    WHERE
        d.d_year = 2001
        AND cc.cc_mkt_class = 'National'
        AND cc.cc_company = 3
        AND c.c_birth_month = 7
        AND c.c_birth_year BETWEEN 1960 AND 1970
        AND d.d_weekend = 'N'
    UNION ALL
    SELECT
        d.d_year,
        d.d_month_seq,
        CAST(NULL AS integer) AS cc_call_center_sk,
        CAST(NULL AS varchar) AS call_center_name,
        w.w_warehouse_sk,
        w.w_warehouse_name AS warehouse_name,
        wsit.web_name AS web_site_name,
        ws.ws_ext_sales_price AS sales_price,
        ws.ws_ext_discount_amt AS discount_amt,
        ws.ws_order_number AS order_number,
        ws.ws_bill_customer_sk AS customer_sk
    FROM web_sales ws
    JOIN date_dim d
        ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN web_site wsit
        ON ws.ws_web_site_sk = wsit.web_site_sk
    JOIN warehouse w
        ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN customer c
        ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE
        d.d_year = 2001
        AND wsit.web_class = 'A'
        AND w.w_state = 'CA'
        AND c.c_birth_month = 7
        AND d.d_weekend = 'N'
        AND EXISTS (
            SELECT 1
            FROM web_page wp2
            WHERE wp2.wp_customer_sk = c.c_customer_sk
              AND wp2.wp_type = 'A'
        )
),
aggregated_sales AS (
    SELECT
        d_year,
        d_month_seq,
        call_center_name,
        warehouse_name,
        web_site_name,
        SUM(sales_price) AS total_sales,
        SUM(discount_amt) AS total_discount,
        COUNT(DISTINCT order_number) AS distinct_orders,
        AVG(sales_price) AS avg_sales_price,
        (SUM(discount_amt) / NULLIF(COUNT(*), 0)) AS avg_discount_per_row
    FROM combined_sales
    GROUP BY
        d_year,
        d_month_seq,
        call_center_name,
        warehouse_name,
        web_site_name
    HAVING
        SUM(sales_price) > 1000000
)
SELECT
    a.d_year,
    a.d_month_seq,
    a.call_center_name,
    a.warehouse_name,
    a.web_site_name,
    a.total_sales,
    a.total_discount,
    a.distinct_orders,
    a.avg_sales_price,
    a.avg_discount_per_row,
    RANK() OVER (PARTITION BY a.d_year ORDER BY a.total_sales DESC) AS sales_rank,
    (SELECT AVG(cs2.discount_amt)
     FROM combined_sales cs2
     WHERE cs2.d_year = a.d_year) AS overall_avg_discount
FROM aggregated_sales a
ORDER BY a.total_sales DESC
LIMIT 100
