WITH
    inner_agg AS (
        SELECT
            s.s_state,
            s.s_city,
            SUM(ss.ss_net_paid) AS total_net_paid
        FROM store_sales ss
        JOIN store s
            ON ss.ss_store_sk = s.s_store_sk
        WHERE
            s.s_state IN ('CA', 'TX', 'NY')
            AND s.s_rec_start_date BETWEEN DATE '1999-01-01' AND DATE '2000-12-31'
            AND ss.ss_sales_price > 20
        GROUP BY s.s_state, s.s_city
    ),
    full_join_agg AS (
        SELECT
            s.s_state,
            s.s_city,
            SUM(ss.ss_net_paid) AS total_net_paid
        FROM store s
        FULL OUTER JOIN store_sales ss
            ON s.s_store_sk = ss.ss_store_sk
        WHERE
            (s.s_state IS NOT NULL AND s.s_state NOT IN ('CA', 'TX', 'NY'))
            OR (ss.ss_sales_price IS NOT NULL AND ss.ss_sales_price > 20)
        GROUP BY s.s_state, s.s_city
    ),
    unioned AS (
        SELECT s_state, s_city, total_net_paid FROM inner_agg
        UNION
        SELECT s_state, s_city, total_net_paid FROM full_join_agg
    ),
    rolled AS (
        SELECT
            s_state,
            s_city,
            SUM(total_net_paid) AS grp_total_net_paid
        FROM unioned
        GROUP BY ROLLUP (s_state, s_city)
    )
SELECT
    s_state,
    s_city,
    grp_total_net_paid,
    DENSE_RANK() OVER (ORDER BY grp_total_net_paid DESC) AS sales_rank,
    (SELECT AVG(ss2.ss_sales_price) FROM store_sales ss2) AS avg_sales_price
FROM rolled
WHERE grp_total_net_paid IS NOT NULL
ORDER BY sales_rank, s_state, s_city
LIMIT 100
