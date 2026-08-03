WITH intersect_customers AS (
    SELECT sr_customer_sk FROM (
        SELECT DISTINCT sr.sr_customer_sk
        FROM store_returns sr
        JOIN date_dim d1 ON sr.sr_returned_date_sk = d1.d_date_sk
        WHERE d1.d_year = 2020
          AND sr.sr_return_amt > 100
    )
    INTERSECT
    SELECT wp_customer_sk FROM (
        SELECT DISTINCT wp.wp_customer_sk
        FROM web_page wp
        JOIN date_dim d2 ON wp.wp_creation_date_sk = d2.d_date_sk
        WHERE d2.d_year = 2020
          AND wp.wp_type = 'article'
    )
)
SELECT
    c.c_customer_sk,
    c.c_first_name,
    c.c_last_name,
    cd.cd_credit_rating,
    d.d_year,
    SUM(sr.sr_return_amt) AS yearly_return_total,
    RANK() OVER (PARTITION BY d.d_year ORDER BY SUM(sr.sr_return_amt) DESC) AS return_rank,
    (
        SELECT SUM(sr_inner.sr_return_amt)
        FROM store_returns sr_inner
        WHERE sr_inner.sr_customer_sk = c.c_customer_sk
    ) AS total_return_all_years,
    (
        SELECT COUNT(DISTINCT wp_inner.wp_url)
        FROM web_page wp_inner
        JOIN date_dim d_inner ON wp_inner.wp_creation_date_sk = d_inner.d_date_sk
        WHERE wp_inner.wp_customer_sk = c.c_customer_sk
          AND d_inner.d_year = d.d_year
    ) AS distinct_pages_visited,
    cc.cc_name,
    cc.cc_state
FROM store_returns sr
JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
LEFT JOIN call_center cc ON (cc.cc_closed_date_sk = d.d_date_sk OR cc.cc_open_date_sk = d.d_date_sk)
LEFT JOIN web_page wp ON wp.wp_customer_sk = c.c_customer_sk
    AND (wp.wp_creation_date_sk = d.d_date_sk OR wp.wp_access_date_sk = d.d_date_sk)
WHERE
    cd.cd_credit_rating = 'High Risk'
    AND d.d_year = 2020
    AND t.t_hour BETWEEN 9 AND 17
    AND cc.cc_state = 'CA'
    AND c.c_customer_sk IN (SELECT sr_customer_sk FROM intersect_customers)
    AND EXISTS (
        SELECT 1
        FROM call_center cc2
        WHERE cc2.cc_company_name = 'XYZ Corp'
          AND cc2.cc_closed_date_sk = d.d_date_sk
    )
GROUP BY
    c.c_customer_sk,
    c.c_first_name,
    c.c_last_name,
    cd.cd_credit_rating,
    d.d_year,
    cc.cc_name,
    cc.cc_state
ORDER BY yearly_return_total DESC
LIMIT 100
