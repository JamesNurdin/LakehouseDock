WITH filtered_pages AS (
    SELECT
        cp_catalog_page_sk,
        cp_department,
        cp_description,
        regexp_extract(cp_description, '(?i)(economic|services)', 1) AS description_keyword
    FROM catalog_page
    WHERE regexp_like(cp_description, '(?i)economic|services')
       OR cp_description LIKE '%year%'
),
agg_returns AS (
    SELECT
        fp.cp_department,
        d.d_year,
        MAX(fp.description_keyword) AS description_keyword,
        SUM(cr.cr_net_loss) AS total_net_loss,
        COUNT(*) AS returns_cnt,
        AVG(cr.cr_net_loss) AS avg_net_loss
    FROM filtered_pages fp
    JOIN catalog_returns cr
        ON fp.cp_catalog_page_sk = cr.cr_catalog_page_sk
    JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    WHERE EXISTS (
        SELECT 1
        FROM customer_address ca
        WHERE ca.ca_address_sk = cr.cr_returning_addr_sk
          AND ca.ca_state = 'CA'
    )
    GROUP BY GROUPING SETS (
        (fp.cp_department, d.d_year),
        (fp.cp_department),
        ()
    )
)
SELECT
    cp_department,
    d_year,
    description_keyword,
    CONCAT(cp_department, ':', COALESCE(description_keyword, 'N/A')) AS dept_desc,
    total_net_loss,
    returns_cnt,
    avg_net_loss,
    ROW_NUMBER() OVER (PARTITION BY cp_department ORDER BY total_net_loss DESC) AS dept_loss_rank,
    (SELECT COUNT(DISTINCT d2.d_year) FROM date_dim d2) AS distinct_years_total
FROM agg_returns
ORDER BY cp_department, d_year
LIMIT 100
