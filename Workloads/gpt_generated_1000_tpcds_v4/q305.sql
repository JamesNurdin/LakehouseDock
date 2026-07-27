SELECT
    web_site_id,
    web_name,
    web_city,
    web_state,
    web_gmt_offset,
    web_tax_percentage
FROM
    tpcds.web_site
WHERE
    web_rec_start_date >= DATE '2000-01-01'
    AND web_suite_number LIKE 'Suite 4%'
LIMIT 100
