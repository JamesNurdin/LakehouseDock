WITH store_sales_agg AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        s.s_manager,
        s.s_hours,
        s.s_city,
        s.s_state,
        d.d_year,
        c.c_email_address,
        SUM(ss.ss_net_profit) AS total_profit,
        COUNT(*) AS sales_cnt
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    WHERE regexp_like(c.c_email_address, '@example\\.com$')
    GROUP BY
        s.s_store_id,
        s.s_store_name,
        s.s_manager,
        s.s_hours,
        s.s_city,
        s.s_state,
        d.d_year,
        c.c_email_address
)
SELECT
    sa.s_store_id,
    sa.s_store_name,
    concat(sa.s_city, ', ', sa.s_state) AS store_location,
    sa.d_year,
    sa.total_profit,
    sa.sales_cnt,
    CASE
        WHEN sa.total_profit > 20000 THEN 'High'
        WHEN sa.total_profit BETWEEN 5000 AND 20000 THEN 'Medium'
        ELSE 'Low'
    END AS profit_category,
    regexp_extract(sa.s_manager, '^([A-Z])', 1) AS manager_initial,
    regexp_extract(sa.c_email_address, '@([^.]*)\\.', 1) AS email_domain,
    (SELECT AVG(total_profit) FROM store_sales_agg WHERE d_year = sa.d_year) AS avg_profit_year,
    (SELECT MAX(total_profit) FROM store_sales_agg WHERE s_store_id = sa.s_store_id) AS max_store_profit
FROM store_sales_agg sa
WHERE
    regexp_like(sa.s_manager, '^J')
    AND sa.s_hours LIKE '%8AM%'
    AND sa.total_profit > (SELECT AVG(total_profit) * 1.5 FROM store_sales_agg)
ORDER BY sa.total_profit DESC
LIMIT 100
