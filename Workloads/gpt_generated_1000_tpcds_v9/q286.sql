WITH pref AS (
    SELECT
        s.s_store_id,
        MAX(s.s_store_name) AS s_store_name,
        MAX(s.s_state) AS s_state,
        MAX(s.s_tax_percentage) AS s_tax_percentage,
        d_common.d_year AS sales_year,
        COUNT(*) AS cust_cnt,
        AVG(c.c_birth_year) AS avg_birth_year,
        CASE WHEN COUNT(*) > 200 THEN 'High' ELSE 'Low' END AS volume_category
    FROM store s
    JOIN date_dim d_common ON s.s_closed_date_sk = d_common.d_date_sk
    JOIN customer c ON c.c_first_sales_date_sk = d_common.d_date_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN date_dim d_shipto ON c.c_first_shipto_date_sk = d_shipto.d_date_sk
    WHERE
        s.s_geography_class = 'Unknown'
        AND ca.ca_zip LIKE '5%'
        AND c.c_email_address LIKE '%.com'
        AND d_common.d_date BETWEEN DATE '1999-01-01' AND DATE '1999-12-31'
        AND c.c_preferred_cust_flag = 'Y'
    GROUP BY ROLLUP (s.s_store_id, d_common.d_year)
),
nonpref AS (
    SELECT
        s.s_store_id,
        MAX(s.s_store_name) AS s_store_name,
        MAX(s.s_state) AS s_state,
        MAX(s.s_tax_percentage) AS s_tax_percentage,
        d_common.d_year AS sales_year,
        COUNT(*) AS cust_cnt,
        AVG(c.c_birth_year) AS avg_birth_year,
        CASE WHEN COUNT(*) > 200 THEN 'High' ELSE 'Low' END AS volume_category
    FROM store s
    JOIN date_dim d_common ON s.s_closed_date_sk = d_common.d_date_sk
    JOIN customer c ON c.c_first_sales_date_sk = d_common.d_date_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN date_dim d_shipto ON c.c_first_shipto_date_sk = d_shipto.d_date_sk
    WHERE
        s.s_geography_class = 'Unknown'
        AND ca.ca_zip LIKE '7%'
        AND c.c_email_address LIKE '%.org'
        AND d_common.d_date BETWEEN DATE '1999-01-01' AND DATE '1999-12-31'
        AND c.c_preferred_cust_flag <> 'Y'
    GROUP BY ROLLUP (s.s_store_id, d_common.d_year)
),
combined AS (
    SELECT * FROM pref
    UNION ALL
    SELECT * FROM nonpref
),
ranked AS (
    SELECT
        c.*,
        RANK() OVER (PARTITION BY c.sales_year ORDER BY c.cust_cnt DESC) AS store_rank
    FROM combined c
)
SELECT
    r.s_store_id,
    r.s_store_name,
    r.sales_year,
    r.cust_cnt,
    r.avg_birth_year,
    r.volume_category,
    r.store_rank,
    CASE WHEN r.store_rank <= 3 THEN 'Top' ELSE 'Other' END AS rank_group,
    (
        SELECT AVG(v.cust_cnt)
        FROM combined v
        WHERE v.sales_year = r.sales_year
    ) AS avg_cust_cnt_year
FROM ranked r
WHERE r.s_tax_percentage > (
    SELECT AVG(s2.s_tax_percentage)
    FROM store s2
    WHERE s2.s_state = r.s_state
)
ORDER BY r.sales_year, r.store_rank
