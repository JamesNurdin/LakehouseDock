WITH
    page_set_a AS (
        SELECT cp.cp_catalog_page_sk
        FROM catalog_page cp
        WHERE cp.cp_department = 'Sports'
    ),
    page_set_b AS (
        SELECT cp.cp_catalog_page_sk
        FROM catalog_page cp
        JOIN promotion p ON p.p_start_date_sk = cp.cp_start_date_sk
        WHERE p.p_discount_active = 'Y'
    ),
    intersect_pages AS (
        SELECT cp_catalog_page_sk FROM page_set_a INTERSECT SELECT cp_catalog_page_sk FROM page_set_b
    ),
    except_pages AS (
        SELECT cp_catalog_page_sk FROM page_set_a EXCEPT SELECT cp_catalog_page_sk FROM page_set_b
    ),
    base AS (
        SELECT
            cp.cp_catalog_page_sk,
            cp.cp_department,
            d_ret.d_year,
            d_ret.d_month_seq,
            p.p_promo_name,
            cr.cr_return_amount,
            cr.cr_return_tax,
            cr.cr_return_quantity,
            cr.cr_return_ship_cost,
            CASE WHEN cr.cr_return_amount > 500 THEN 1 ELSE 0 END AS high_return_flag
        FROM catalog_returns cr
        JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
        JOIN date_dim d_ret ON cr.cr_returned_date_sk = d_ret.d_date_sk
        JOIN customer c ON cr.cr_returning_customer_sk = c.c_customer_sk
        JOIN date_dim d_cp_start ON cp.cp_start_date_sk = d_cp_start.d_date_sk
        JOIN promotion p ON p.p_start_date_sk = d_cp_start.d_date_sk
        WHERE d_ret.d_year = 2002
          AND cp.cp_department = 'Sports'
          AND c.c_birth_country = 'USA'
          AND p.p_discount_active = 'Y'
          AND cr.cr_return_amount > 100
    )
SELECT
    b.cp_department,
    b.p_promo_name,
    b.d_year,
    b.d_month_seq,
    COUNT(*) AS return_count,
    SUM(b.cr_return_amount) AS total_return_amount,
    AVG(b.cr_return_tax) AS avg_return_tax,
    MIN(b.cr_return_ship_cost) AS min_ship_cost,
    MAX(b.cr_return_quantity) AS max_quantity,
    SUM(CASE WHEN b.cr_return_amount > 500 THEN b.cr_return_amount ELSE 0 END) AS high_return_sum,
    COUNT(DISTINCT b.cp_catalog_page_sk) FILTER (WHERE b.cp_catalog_page_sk IN (SELECT cp_catalog_page_sk FROM intersect_pages)) AS intersect_page_cnt,
    COUNT(DISTINCT b.cp_catalog_page_sk) FILTER (WHERE b.cp_catalog_page_sk IN (SELECT cp_catalog_page_sk FROM except_pages)) AS except_page_cnt
FROM base b
GROUP BY b.cp_department, b.p_promo_name, b.d_year, b.d_month_seq
ORDER BY total_return_amount DESC
LIMIT 100
