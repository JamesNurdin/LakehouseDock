WITH aggregated AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        s.s_company_name,
        d_ship.d_year AS ship_year,
        d_ship.d_quarter_name AS ship_quarter,
        COUNT(c.c_customer_sk) AS customer_cnt,
        AVG(c.c_birth_year) AS avg_birth_year,
        MIN(c.c_birth_day) AS min_birth_day,
        MAX(c.c_birth_day) AS max_birth_day
    FROM customer c
    JOIN date_dim d_ship ON c.c_first_shipto_date_sk = d_ship.d_date_sk
    JOIN date_dim d_sales ON c.c_first_sales_date_sk = d_sales.d_date_sk
    JOIN store s ON s.s_closed_date_sk = d_ship.d_date_sk
    WHERE
        d_ship.d_current_quarter = 'Y'
        AND d_ship.d_following_holiday = 'N'
        AND d_sales.d_year = 2000
        AND s.s_company_name = 'Unknown'
        AND s.s_rec_start_date >= DATE '1999-01-01'
        AND s.s_rec_end_date <= DATE '2002-12-31'
        AND c.c_preferred_cust_flag = 'Y'
        AND c.c_birth_day IN (8, 15, 17)
    GROUP BY
        s.s_store_id,
        s.s_store_name,
        s.s_company_name,
        d_ship.d_year,
        d_ship.d_quarter_name
)
SELECT
    a.s_store_id,
    a.s_store_name,
    a.s_company_name,
    a.ship_year,
    a.ship_quarter,
    a.customer_cnt,
    a.avg_birth_year,
    a.min_birth_day,
    a.max_birth_day,
    RANK() OVER (ORDER BY a.customer_cnt DESC) AS store_customer_rank
FROM aggregated a
ORDER BY a.customer_cnt DESC, a.s_store_id
LIMIT 100
