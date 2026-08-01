WITH
    -- Pre‑aggregate sales per item from a sampled portion of catalog_sales
    item_sales AS (
        SELECT
            cs_item_sk,
            SUM(cs_quantity) AS total_qty,
            SUM(cs_net_paid) AS total_net_paid,
            COUNT(*) AS sales_cnt
        FROM tpcds.catalog_sales TABLESAMPLE BERNOULLI (10)
        WHERE cs_sold_date_sk BETWEEN 2450646 AND 2452168
        GROUP BY cs_item_sk
    ),
    -- Customers that have sales on a specific date but are not marked as preferred customers
    eligible_customers AS (
        SELECT cs_bill_customer_sk AS c_customer_sk
        FROM tpcds.catalog_sales
        WHERE cs_sold_date_sk = 2450646
        EXCEPT
        SELECT c_customer_sk
        FROM tpcds.customer
        WHERE c_preferred_cust_flag = 'Y'
    )
SELECT
    final.c_customer_id,
    final.i_item_id,
    final.cp_catalog_number,
    final.w_warehouse_name,
    final.wp_type,
    final.total_qty,
    final.total_net_paid,
    final.sales_cnt,
    final.max_net_paid,
    final.min_net_paid,
    final.avg_net_paid,
    final.max_page_num
FROM (
    -- First branch: items whose formulation contains 'moccasin'
    SELECT
        c.c_customer_id,
        i.i_item_id,
        cp.cp_catalog_number,
        w.w_warehouse_name,
        wp.wp_type,
        isales.total_qty,
        isales.total_net_paid,
        isales.sales_cnt,
        MAX(cs.cs_net_paid) AS max_net_paid,
        MIN(cs.cs_net_paid) AS min_net_paid,
        AVG(cs.cs_net_paid) AS avg_net_paid,
        lc.max_page_num
    FROM eligible_customers ec
    JOIN tpcds.customer c ON ec.c_customer_sk = c.c_customer_sk
    JOIN tpcds.catalog_sales cs ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN tpcds.catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN tpcds.warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN tpcds.item i ON cs.cs_item_sk = i.i_item_sk
    JOIN tpcds.web_page wp ON wp.wp_customer_sk = c.c_customer_sk
    JOIN item_sales isales ON cs.cs_item_sk = isales.cs_item_sk
    CROSS JOIN LATERAL (
        SELECT MAX(cp2.cp_catalog_page_number) AS max_page_num
        FROM tpcds.catalog_page cp2
        WHERE cp2.cp_catalog_page_sk = cs.cs_catalog_page_sk
    ) AS lc
    WHERE i.i_formulation LIKE '%moccasin%'
      AND cp.cp_catalog_number IN (12, 17)
      AND w.w_state = 'CA'
      AND wp.wp_type = 'home'
      AND c.c_first_sales_date_sk = 2450646
      AND c.c_birth_month = 5
      AND c.c_birth_day = 15
    GROUP BY
        c.c_customer_id,
        i.i_item_id,
        cp.cp_catalog_number,
        w.w_warehouse_name,
        wp.wp_type,
        isales.total_qty,
        isales.total_net_paid,
        isales.sales_cnt,
        lc.max_page_num

    UNION DISTINCT

    -- Second branch: items whose formulation contains 'papaya'
    SELECT
        c.c_customer_id,
        i.i_item_id,
        cp.cp_catalog_number,
        w.w_warehouse_name,
        wp.wp_type,
        isales.total_qty,
        isales.total_net_paid,
        isales.sales_cnt,
        MAX(cs.cs_net_paid) AS max_net_paid,
        MIN(cs.cs_net_paid) AS min_net_paid,
        AVG(cs.cs_net_paid) AS avg_net_paid,
        lc.max_page_num
    FROM eligible_customers ec
    JOIN tpcds.customer c ON ec.c_customer_sk = c.c_customer_sk
    JOIN tpcds.catalog_sales cs ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN tpcds.catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN tpcds.warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN tpcds.item i ON cs.cs_item_sk = i.i_item_sk
    JOIN tpcds.web_page wp ON wp.wp_customer_sk = c.c_customer_sk
    JOIN item_sales isales ON cs.cs_item_sk = isales.cs_item_sk
    CROSS JOIN LATERAL (
        SELECT MAX(cp2.cp_catalog_page_number) AS max_page_num
        FROM tpcds.catalog_page cp2
        WHERE cp2.cp_catalog_page_sk = cs.cs_catalog_page_sk
    ) AS lc
    WHERE i.i_formulation LIKE '%papaya%'
      AND cp.cp_catalog_number IN (12, 17)
      AND w.w_state = 'CA'
      AND wp.wp_type = 'home'
      AND c.c_first_sales_date_sk = 2450646
      AND c.c_birth_month = 5
      AND c.c_birth_day = 15
    GROUP BY
        c.c_customer_id,
        i.i_item_id,
        cp.cp_catalog_number,
        w.w_warehouse_name,
        wp.wp_type,
        isales.total_qty,
        isales.total_net_paid,
        isales.sales_cnt,
        lc.max_page_num
) AS final
ORDER BY final.total_net_paid DESC
LIMIT 100
