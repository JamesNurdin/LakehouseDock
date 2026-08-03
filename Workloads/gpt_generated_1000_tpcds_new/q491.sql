WITH
    purchasers AS (
        SELECT DISTINCT ss.ss_customer_sk
        FROM store_sales ss
        JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
        WHERE d.d_year = 2001
    ),
    returners AS (
        SELECT DISTINCT cr.cr_returning_customer_sk
        FROM catalog_returns cr
        JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
        WHERE d.d_year = 2001
    ),
    exclusive_customers AS (
        SELECT ss_customer_sk FROM purchasers
        EXCEPT
        SELECT cr_returning_customer_sk FROM returners
    ),
    stores_with_exclusive AS (
        SELECT DISTINCT ss.ss_store_sk
        FROM store_sales ss
        JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
        WHERE d.d_year = 2001
          AND ss.ss_customer_sk IN (SELECT ss_customer_sk FROM exclusive_customers)
    ),
    cte_store_sales AS (
        SELECT
            s.s_store_sk,
            s.s_store_id,
            s.s_store_name,
            concat(s.s_city, ', ', s.s_state) AS store_location,
            regexp_extract(c.c_email_address, '@([^@]+)$', 1) AS email_domain,
            sum(ss.ss_net_profit) AS total_profit,
            sum(ss.ss_ext_sales_price) AS total_sales
        FROM store_sales ss
        JOIN store s ON ss.ss_store_sk = s.s_store_sk
        JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
        JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
        WHERE d.d_year = 2001
          AND regexp_like(c.c_email_address, '^.+@example\\.com$')
          AND ss.ss_store_sk IN (SELECT ss_store_sk FROM stores_with_exclusive)
        GROUP BY s.s_store_sk, s.s_store_id, s.s_store_name, s.s_city, s.s_state, c.c_email_address
    ),
    cte_catalog_sales AS (
        SELECT
            cp.cp_catalog_page_id,
            cp.cp_description,
            sum(cs.cs_net_profit) AS total_profit,
            sum(cs.cs_ext_sales_price) AS total_sales
        FROM catalog_sales cs
        JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
        JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
        WHERE d.d_year = 2001
          AND regexp_like(cp.cp_description, '(?i)garden')
        GROUP BY cp.cp_catalog_page_id, cp.cp_description
    )
SELECT
    'store' AS entity_type,
    s_store_id AS entity_id,
    store_location AS description,
    total_profit AS metric,
    email_domain AS extra_info
FROM cte_store_sales

UNION DISTINCT

SELECT
    'catalog_page' AS entity_type,
    cp_catalog_page_id AS entity_id,
    cp_description AS description,
    total_profit AS metric,
    CAST(NULL AS varchar) AS extra_info
FROM cte_catalog_sales

ORDER BY metric DESC
OFFSET 0 ROWS FETCH NEXT 20 ROWS ONLY
