WITH filtered_promos AS (
    SELECT
        p.p_promo_sk,
        p.p_channel_tv,
        regexp_extract(p.p_channel_details, '(?i)(family)', 1) AS extracted_term
    FROM promotion p
    WHERE regexp_like(p.p_channel_details, '(?i)family')
      AND p.p_channel_tv = 'N'
)
SELECT
    d.d_year AS year,
    fp.p_channel_tv AS tv_channel,
    fp.extracted_term AS promo_term,
    CONCAT(cp.cp_department, ': ', cp.cp_description) AS dept_desc,
    SUM(cs.cs_net_paid) AS total_net_paid,
    COUNT(*) AS sales_count
FROM catalog_sales cs
JOIN filtered_promos fp ON cs.cs_promo_sk = fp.p_promo_sk
JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
WHERE cp.cp_description LIKE '%new%'
GROUP BY d.d_year, fp.p_channel_tv, fp.extracted_term, cp.cp_department, cp.cp_description
ORDER BY total_net_paid DESC
LIMIT 100
