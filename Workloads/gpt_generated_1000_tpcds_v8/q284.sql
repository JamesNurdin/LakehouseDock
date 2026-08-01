WITH filtered_web_page AS (
    SELECT wp_web_page_sk,
           wp_url,
           wp_type,
           wp_customer_sk
    FROM web_page
    WHERE wp_url IS NOT NULL
      AND regexp_like(wp_url, '^https?://[^/]+/sports/')
      AND wp_type LIKE 'Content%'
),
filtered_customer AS (
    SELECT c_customer_sk,
           c_first_name,
           c_last_name,
           c_email_address,
           c_current_cdemo_sk,
           c_current_addr_sk
    FROM customer
    WHERE c_email_address LIKE '%@example.com'
),
joined AS (
    SELECT
        wr.wr_refunded_customer_sk,
        wr.wr_return_amt,
        wr.wr_return_ship_cost,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        ca.ca_state,
        concat(fc.c_first_name, ' ', fc.c_last_name) AS full_name,
        regexp_extract(fc.c_email_address, '@([^\\.]+)\\.', 1) AS email_domain
    FROM web_returns wr
    JOIN filtered_customer fc
        ON wr.wr_refunded_customer_sk = fc.c_customer_sk
    JOIN customer_demographics cd
        ON fc.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca
        ON fc.c_current_addr_sk = ca.ca_address_sk
    WHERE wr.wr_web_page_sk IN (SELECT wp_web_page_sk FROM filtered_web_page)
),
agg AS (
    SELECT
        cd_education_status,
        email_domain,
        COUNT(*) AS return_cnt,
        SUM(wr_return_amt) AS total_refund,
        AVG(wr_return_ship_cost) AS avg_ship_cost
    FROM joined
    GROUP BY cd_education_status, email_domain
)
SELECT
    cd_education_status,
    email_domain,
    return_cnt,
    total_refund,
    avg_ship_cost,
    ROW_NUMBER() OVER (ORDER BY total_refund DESC) AS rn
FROM agg
ORDER BY total_refund DESC
LIMIT 100
