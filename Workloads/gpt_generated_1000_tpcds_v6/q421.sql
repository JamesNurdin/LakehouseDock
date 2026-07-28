WITH sales_agg AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(cs.cs_net_paid) AS catalog_net_paid,
        SUM(ws.ws_net_paid) AS web_net_paid
    FROM catalog_sales cs
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN web_sales ws
        ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE cp.cp_department = 'Electronics'
      AND cs.cs_sold_date_sk BETWEEN 2450000 AND 2452000
      AND ws.ws_sold_date_sk BETWEEN 2450000 AND 2452000
      AND c.c_preferred_cust_flag = 'Y'
      AND cs.cs_ext_discount_amt > 500
      AND ws.ws_net_paid > 1000
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
avg_total AS (
    SELECT AVG(catalog_net_paid + web_net_paid) AS avg_total
    FROM sales_agg
)
SELECT
    sa.c_customer_sk,
    sa.c_first_name,
    sa.c_last_name,
    sa.catalog_net_paid,
    sa.web_net_paid,
    (sa.catalog_net_paid + sa.web_net_paid) AS total_net_paid,
    RANK() OVER (ORDER BY (sa.catalog_net_paid + sa.web_net_paid) DESC) AS sales_rank,
    CASE
        WHEN (sa.catalog_net_paid + sa.web_net_paid) > (SELECT avg_total FROM avg_total) THEN 'Above Avg'
        ELSE 'Below Avg'
    END AS performance_flag
FROM sales_agg sa
ORDER BY sales_rank
LIMIT 20
