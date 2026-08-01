WITH
segment_a AS (
    SELECT
        cc.cc_call_center_sk,
        cc.cc_company_name,
        cc.cc_state,
        cc.cc_country,
        SUM(cs.cs_net_paid_inc_ship_tax) AS total_net_paid
    FROM tpcds.call_center cc
    JOIN tpcds.catalog_sales cs
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    WHERE cc.cc_company_name = 'anti'
        AND cs.cs_net_paid_inc_ship_tax >= 1000
    GROUP BY cc.cc_call_center_sk, cc.cc_company_name, cc.cc_state, cc.cc_country
),
segment_b AS (
    SELECT
        cc.cc_call_center_sk,
        cc.cc_company_name,
        cc.cc_state,
        cc.cc_country,
        SUM(cs.cs_net_paid_inc_ship_tax) AS total_net_paid
    FROM tpcds.call_center cc
    JOIN tpcds.catalog_sales cs
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    WHERE cc.cc_company_name = 'ese'
        AND cs.cs_net_paid_inc_ship_tax < 5000
    GROUP BY cc.cc_call_center_sk, cc.cc_company_name, cc.cc_state, cc.cc_country
),
combined AS (
    SELECT * FROM segment_a
    UNION ALL
    SELECT * FROM segment_b
),
expanded AS (
    SELECT
        c.cc_call_center_sk,
        c.cc_company_name,
        c.cc_state,
        c.cc_country,
        c.total_net_paid,
        loc AS location
    FROM combined c
    CROSS JOIN UNNEST(ARRAY[c.cc_state, c.cc_country]) AS t(loc)
),
agg AS (
    SELECT
        cc_company_name,
        cc_state,
        location,
        SUM(total_net_paid) AS sum_net_paid
    FROM expanded
    GROUP BY ROLLUP(cc_company_name, cc_state, location)
)
SELECT
    cc_company_name,
    cc_state,
    location,
    sum_net_paid,
    ROW_NUMBER() OVER (PARTITION BY cc_company_name ORDER BY sum_net_paid DESC) AS rank_in_company
FROM agg
ORDER BY cc_company_name, rank_in_company
LIMIT 100
