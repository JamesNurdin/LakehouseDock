WITH
    relevant_pages AS (
        SELECT cp_catalog_page_sk
        FROM catalog_page
        WHERE regexp_like(cp_description, '(?i)blue')
          AND cp_description LIKE '%sales%'
    ),
    other_pages AS (
        SELECT cp_catalog_page_sk
        FROM catalog_page
        WHERE cp_catalog_number < 10
    ),
    pages_to_use AS (
        SELECT cp_catalog_page_sk FROM relevant_pages
        EXCEPT
        SELECT cp_catalog_page_sk FROM other_pages
    ),
    sales_data AS (
        SELECT
            cs.cs_order_number,
            cs.cs_sold_date_sk,
            cs.cs_catalog_page_sk,
            cs.cs_net_paid_inc_ship_tax,
            cs.cs_quantity,
            sm.sm_code,
            d.d_year,
            d.d_month_seq,
            cp.cp_department,
            cp.cp_description
        FROM catalog_sales cs
        JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
        JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
        JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
        WHERE cs.cs_catalog_page_sk IN (SELECT cp_catalog_page_sk FROM pages_to_use)
    ),
    orders_without_returns AS (
        SELECT cs_order_number
        FROM sales_data
        EXCEPT
        SELECT cr.cr_order_number
        FROM catalog_returns cr
    ),
    aggregated AS (
        SELECT
            sd.cp_department,
            sd.sm_code,
            sd.d_year,
            sd.d_month_seq,
            SUM(sd.cs_net_paid_inc_ship_tax) AS total_net_paid,
            SUM(sd.cs_quantity) AS total_quantity,
            MIN(sd.cp_description) AS any_description
        FROM sales_data sd
        JOIN orders_without_returns ow ON sd.cs_order_number = ow.cs_order_number
        GROUP BY sd.cp_department, sd.sm_code, sd.d_year, sd.d_month_seq
    )
SELECT
    a.cp_department,
    a.sm_code,
    a.d_year,
    a.d_month_seq,
    a.total_net_paid,
    a.total_quantity,
    substring(a.any_description, 1, 30) AS desc_snippet,
    regexp_extract(a.any_description, '(?i)(blue|sales)', 1) AS matched_word,
    concat(a.cp_department, ':', a.sm_code) AS dept_ship_key,
    ROW_NUMBER() OVER (ORDER BY a.total_net_paid DESC) AS global_row_num,
    RANK() OVER (PARTITION BY a.cp_department ORDER BY a.total_net_paid DESC) AS dept_rank,
    (SELECT COUNT(*) FROM catalog_returns) AS total_returns_all
FROM aggregated a
WHERE a.cp_department NOT IN (SELECT cp_department FROM catalog_page WHERE cp_department = 'Unknown')
ORDER BY a.total_net_paid DESC
LIMIT 100
