WITH filtered_sales AS (
    SELECT
        cs.cs_bill_customer_sk,
        cs.cs_item_sk,
        cs.cs_net_paid,
        cp.cp_department,
        cp.cp_description,
        cp.cp_type,
        regexp_extract(cp.cp_description, '(\\d{3,})', 1) AS model_code,
        p.p_promo_name,
        d.d_year
    FROM catalog_sales cs
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    JOIN date_dim d
        ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE regexp_like(cp.cp_description, '[A-Z]-[0-9]{3,}')
      AND cp.cp_type LIKE 'catalog%'
      AND p.p_promo_name LIKE '%discount%'
),

customer_agg AS (
    SELECT
        c.c_customer_sk,
        concat(c.c_first_name, ' ', c.c_last_name) AS customer_name,
        fs.model_code,
        sum(fs.cs_net_paid) AS total_net_paid,
        count(*) AS sales_count,
        min(fs.d_year) AS first_year,
        max(fs.d_year) AS last_year
    FROM filtered_sales fs
    JOIN customer c
        ON fs.cs_bill_customer_sk = c.c_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, fs.model_code
)

SELECT DISTINCT
    ca.customer_name,
    ca.model_code,
    ca.total_net_paid,
    ca.sales_count,
    ca.first_year,
    ca.last_year
FROM customer_agg ca
WHERE ca.total_net_paid > 1000
ORDER BY ca.total_net_paid DESC
LIMIT 100
