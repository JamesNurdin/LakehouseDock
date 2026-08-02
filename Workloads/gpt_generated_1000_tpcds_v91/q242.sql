WITH intersected_customers AS (
    SELECT DISTINCT sr.sr_customer_sk AS c_customer_sk
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND sr.sr_return_amt > 100
    INTERSECT
    SELECT DISTINCT c.c_customer_sk
    FROM customer c
    JOIN date_dim d2 ON c.c_first_sales_date_sk = d2.d_date_sk
    WHERE d2.d_year = 2001
      AND c.c_preferred_cust_flag = 'Y'
),
joined_data AS (
    SELECT 
        sr.sr_customer_sk,
        c.c_first_name,
        c.c_last_name,
        ca.ca_state,
        cd.cd_gender,
        d.d_date,
        r.r_reason_desc,
        cp.cp_catalog_number,
        cp.cp_catalog_page_number,
        wp.wp_url,
        ws.web_name,
        SUM(sr.sr_return_amt) AS total_return_amt,
        COUNT(*) AS return_cnt,
        CASE WHEN SUM(sr.sr_return_amt) > 500 THEN 'High' ELSE 'Low' END AS return_category
    FROM store_returns sr
    JOIN intersected_customers ic ON sr.sr_customer_sk = ic.c_customer_sk
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    LEFT JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    LEFT JOIN catalog_page cp ON cp.cp_start_date_sk = d.d_date_sk
    LEFT JOIN web_page wp ON wp.wp_creation_date_sk = d.d_date_sk AND wp.wp_customer_sk = c.c_customer_sk
    LEFT JOIN web_site ws ON ws.web_open_date_sk = d.d_date_sk
    WHERE c.c_birth_year BETWEEN 1960 AND 1980
      AND ca.ca_country = 'United States'
      AND cd.cd_education_status = '4 yr Degree'
      AND d.d_month_seq >= 1200
      AND d.d_year = 2001
      AND d.d_date >= DATE '2001-01-01'
      AND r.r_reason_desc IS NOT NULL
    GROUP BY 
        sr.sr_customer_sk,
        c.c_first_name,
        c.c_last_name,
        ca.ca_state,
        cd.cd_gender,
        d.d_date,
        r.r_reason_desc,
        cp.cp_catalog_number,
        cp.cp_catalog_page_number,
        wp.wp_url,
        ws.web_name
)
SELECT 
    sr_customer_sk,
    c_first_name,
    c_last_name,
    ca_state,
    cd_gender,
    d_date,
    r_reason_desc,
    cp_catalog_number,
    cp_catalog_page_number,
    wp_url,
    web_name,
    total_return_amt,
    return_cnt,
    return_category,
    RANK() OVER (ORDER BY total_return_amt DESC) AS return_rank,
    SUM(total_return_amt) OVER (
        PARTITION BY ca_state 
        ORDER BY total_return_amt 
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cum_return_by_state
FROM joined_data
ORDER BY total_return_amt DESC, return_rank
LIMIT 100
