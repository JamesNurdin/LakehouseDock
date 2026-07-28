WITH sales_agg AS (
    SELECT
        cc.cc_name AS call_center_name,
        cp.cp_type AS catalog_page_type,
        d.d_year,
        SUM(cs.cs_net_paid) AS total_net_paid,
        COUNT(*) AS sales_cnt
    FROM catalog_sales cs
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE
        regexp_like(cp.cp_type, 'annual')               -- type contains the word "annual"
        AND cc.cc_name LIKE '%Center%'
        AND d.d_year BETWEEN 2000 AND 2005
    GROUP BY
        cc.cc_name,
        cp.cp_type,
        d.d_year
)
SELECT
    call_center_name,
    catalog_page_type,
    d_year,
    total_net_paid,
    sales_cnt,
    concat(call_center_name, ' - ', catalog_page_type) AS combined_label,
    regexp_extract(call_center_name, '(\\w+)', 1) AS first_word_cc_name,
    rank() OVER (PARTITION BY d_year ORDER BY total_net_paid DESC) AS year_rank
FROM sales_agg
ORDER BY d_year DESC, total_net_paid DESC
LIMIT 100
