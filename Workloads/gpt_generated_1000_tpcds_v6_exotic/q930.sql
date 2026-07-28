WITH sales_by_center AS (
    SELECT
        cc.cc_call_center_id,
        cc.cc_name,
        CONCAT(cc.cc_city, ', ', cc.cc_state) AS location,
        REGEXP_EXTRACT(cc.cc_county, '(.*) County', 1) AS county_name,
        d_open.d_date AS open_date,
        SUM(ss.ss_net_paid) AS total_net_paid,
        COUNT(DISTINCT ss.ss_ticket_number) AS distinct_tickets,
        COUNT(DISTINCT cd.cd_credit_rating) AS distinct_credit_ratings
    FROM call_center AS cc
    JOIN date_dim AS d_open
        ON cc.cc_open_date_sk = d_open.d_date_sk
    JOIN store_sales AS ss
        ON ss.ss_sold_date_sk = d_open.d_date_sk
    JOIN customer_demographics AS cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    WHERE REGEXP_LIKE(cc.cc_county, 'County$')
      AND cc.cc_tax_percentage > 0.05
      AND (cd.cd_credit_rating LIKE '%Risk' OR REGEXP_LIKE(cd.cd_credit_rating, '^Good$'))
      AND SUBSTRING(cc.cc_street_number FROM 1 FOR 1) = '9'
    GROUP BY
        cc.cc_call_center_id,
        cc.cc_name,
        cc.cc_city,
        cc.cc_state,
        cc.cc_county,
        d_open.d_date
)
SELECT DISTINCT
    cc_call_center_id,
    cc_name,
    location,
    county_name,
    open_date,
    total_net_paid,
    distinct_tickets,
    distinct_credit_ratings
FROM sales_by_center
ORDER BY total_net_paid DESC
LIMIT 100
