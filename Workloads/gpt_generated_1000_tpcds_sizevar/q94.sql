WITH sales_open AS (
    SELECT
        w.web_site_sk,
        w.web_name,
        d.d_year AS year,
        ss.ss_net_profit,
        ss.ss_quantity
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN web_site w ON w.web_open_date_sk = d.d_date_sk
    WHERE
        c.c_birth_country IN ('FIJI', 'SWITZERLAND')
        AND c.c_last_review_date BETWEEN 2452300 AND 2452500
        AND d.d_qoy = 2
        AND d.d_current_day = 'N'
        AND w.web_gmt_offset = -5.00
        AND w.web_street_number = '784'
        AND w.web_rec_end_date >= DATE '2000-01-01'
),
sales_close AS (
    SELECT
        w.web_site_sk,
        w.web_name,
        d.d_year AS year,
        ss.ss_net_profit,
        ss.ss_quantity
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN web_site w ON w.web_close_date_sk = d.d_date_sk
    WHERE
        c.c_birth_country IN ('FIJI', 'SWITZERLAND')
        AND c.c_last_review_date BETWEEN 2452300 AND 2452500
        AND d.d_qoy = 2
        AND d.d_current_day = 'N'
        AND w.web_gmt_offset = -5.00
        AND w.web_street_number = '784'
        AND w.web_rec_end_date >= DATE '2000-01-01'
),
union_sales AS (
    SELECT * FROM sales_open
    UNION
    SELECT * FROM sales_close
),
excluded_sites AS (
    SELECT web_site_sk
    FROM web_site
    WHERE web_class = 'C'
),
included_sites AS (
    SELECT web_site_sk FROM union_sales
    EXCEPT
    SELECT web_site_sk FROM excluded_sites
)
SELECT
    us.web_site_sk,
    ws.web_name,
    us.year,
    SUM(us.ss_net_profit) AS total_net_profit,
    AVG(us.ss_quantity) AS avg_quantity,
    COUNT(*) AS sales_transactions,
    MIN(us.ss_net_profit) AS min_net_profit,
    MAX(us.ss_net_profit) AS max_net_profit
FROM union_sales us
JOIN web_site ws ON us.web_site_sk = ws.web_site_sk
WHERE us.web_site_sk IN (SELECT web_site_sk FROM included_sites)
  AND us.web_site_sk NOT IN (SELECT web_site_sk FROM excluded_sites)
GROUP BY us.web_site_sk, ws.web_name, us.year
ORDER BY total_net_profit DESC
LIMIT 100
