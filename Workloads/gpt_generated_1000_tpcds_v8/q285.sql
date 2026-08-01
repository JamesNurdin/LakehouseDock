WITH
    scalar_max AS (
        SELECT MAX(cs_ext_sales_price) AS max_price
        FROM catalog_sales
        WHERE cs_sold_date_sk = 2451024
    ),
    except_keys AS (
        SELECT cs_catalog_page_sk
        FROM catalog_sales
        EXCEPT
        SELECT ss_store_sk
        FROM store_sales
    ),
    catalog_part AS (
        SELECT
            cp.cp_department,
            cs.cs_ext_sales_price AS cs_ext_sales_price,
            cp.cp_catalog_page_sk,
            td.t_time_sk,
            ROW_NUMBER() OVER (PARTITION BY cp.cp_department ORDER BY cs.cs_ext_sales_price DESC) AS dept_rank
        FROM catalog_sales cs
        JOIN catalog_page cp
            ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
        JOIN time_dim td
            ON cs.cs_sold_time_sk = td.t_time_sk
        WHERE cs.cs_ext_sales_price > (SELECT max_price FROM scalar_max)
          AND cp.cp_catalog_page_sk IN (SELECT cs_catalog_page_sk FROM except_keys)
    ),
    store_part AS (
        SELECT
            ss.ss_store_sk,
            ss.ss_ext_sales_price AS ss_ext_sales_price,
            td.t_time_sk,
            ROW_NUMBER() OVER (PARTITION BY ss.ss_store_sk ORDER BY ss.ss_ext_sales_price DESC) AS store_rank
        FROM store_sales ss
        JOIN time_dim td
            ON ss.ss_sold_time_sk = td.t_time_sk
        WHERE ss.ss_ext_sales_price IS NOT NULL
    ),
    full_combined AS (
        SELECT
            cp.cp_department,
            cp.cs_ext_sales_price,
            sp.ss_store_sk,
            sp.ss_ext_sales_price,
            COALESCE(cp.t_time_sk, sp.t_time_sk) AS t_time_sk,
            cp.dept_rank,
            sp.store_rank
        FROM catalog_part cp
        FULL OUTER JOIN store_part sp
            ON cp.t_time_sk = sp.t_time_sk
    )
SELECT
    t_time_sk,
    cp_department,
    cs_ext_sales_price,
    ss_store_sk,
    ss_ext_sales_price,
    dept_rank,
    store_rank
FROM (
    SELECT
        t_time_sk,
        cp_department,
        cs_ext_sales_price,
        ss_store_sk,
        ss_ext_sales_price,
        dept_rank,
        store_rank
    FROM full_combined
    WHERE cs_ext_sales_price IS NOT NULL

    UNION ALL

    SELECT
        t_time_sk,
        cp_department,
        cs_ext_sales_price,
        ss_store_sk,
        ss_ext_sales_price,
        dept_rank,
        store_rank
    FROM full_combined
    WHERE ss_ext_sales_price IS NOT NULL
) AS final_set
ORDER BY t_time_sk DESC
LIMIT 100
