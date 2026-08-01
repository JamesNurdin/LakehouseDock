WITH cp_filtered AS (
    SELECT
        cp.cp_catalog_page_id,
        cp.cp_department,
        cp.cp_description,
        cp.cp_type,
        cp.cp_start_date_sk
    FROM catalog_page cp
    JOIN date_dim d ON cp.cp_start_date_sk = d.d_date_sk
    WHERE cp.cp_type LIKE 'C%'
      AND regexp_like(cp.cp_description, '\\b[A-Z]{3}\\b')
)
SELECT
    cf.cp_department,
    substring(cf.cp_catalog_page_id, 1, 5) AS catalog_id_prefix,
    CONCAT('Dept_', cf.cp_department) AS dept_label,
    regexp_extract(cf.cp_description, '([A-Z]{3})', 1) AS extracted_code,
    d.d_year,
    d.d_month_seq,
    SUM(sr.sr_net_loss) AS total_net_loss,
    COUNT(*) AS return_count,
    AVG(sr.sr_net_loss) AS avg_net_loss
FROM cp_filtered cf
JOIN date_dim d ON cf.cp_start_date_sk = d.d_date_sk
JOIN store_returns sr ON sr.sr_returned_date_sk = d.d_date_sk
JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
WHERE ca.ca_city LIKE 'New%'
  AND ca.ca_state = 'CA'
GROUP BY
    cf.cp_department,
    cf.cp_catalog_page_id,
    cf.cp_description,
    d.d_year,
    d.d_month_seq
HAVING SUM(sr.sr_net_loss) > 1000
ORDER BY total_net_loss DESC
LIMIT 100
