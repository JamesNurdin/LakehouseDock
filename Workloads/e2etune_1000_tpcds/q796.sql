WITH zip_metrics AS (
    SELECT
        cc.cc_zip AS zip,
        cc.cc_city AS city,
        cc.cc_state AS state,
        SUM(cc.cc_employees) AS total_employees,
        AVG(s.s_tax_percentage) AS avg_store_tax_pct,
        COUNT(DISTINCT s.s_store_sk) AS store_count,
        COUNT(DISTINCT cp.cp_catalog_page_sk) AS catalog_page_count
    FROM call_center cc
    JOIN store s
        ON cc.cc_zip = s.s_zip
        AND cc.cc_state = s.s_state
    LEFT JOIN catalog_page cp
        ON cp.cp_start_date_sk = cc.cc_open_date_sk
    LEFT JOIN customer_address ca
        ON ca.ca_zip = cc.cc_zip
        AND ca.ca_state = cc.cc_state
    WHERE cc.cc_rec_start_date >= DATE '2000-01-01'
      AND cc.cc_rec_end_date <= DATE '2001-12-31'
      AND s.s_rec_start_date >= DATE '2000-01-01'
    GROUP BY cc.cc_zip, cc.cc_city, cc.cc_state
    HAVING SUM(cc.cc_employees) > 1000000
)
SELECT
    zip,
    city,
    state,
    total_employees,
    avg_store_tax_pct,
    store_count,
    catalog_page_count,
    RANK() OVER (ORDER BY total_employees DESC) AS employee_rank
FROM zip_metrics
ORDER BY total_employees DESC, store_count DESC
LIMIT 100
