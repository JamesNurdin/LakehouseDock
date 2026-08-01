WITH RECURSIVE birth_years(year) AS (
    SELECT 1990
    UNION ALL
    SELECT year + 1 FROM birth_years WHERE year < 2000
)
SELECT
    ib.ib_lower_bound AS income_lower,
    ib.ib_upper_bound AS income_upper,
    COUNT(DISTINCT c.c_customer_sk) AS customer_cnt,
    AVG(wp_cnt.page_cnt) AS avg_pages_per_customer,
    (SELECT MAX(ib2.ib_upper_bound) FROM income_band ib2) AS max_income_upper
FROM
    birth_years byr
    JOIN customer c
        ON c.c_birth_year = byr.year
    JOIN household_demographics hd
        ON c.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN (
        SELECT wp.wp_customer_sk, COUNT(*) AS page_cnt
        FROM web_page wp
        WHERE wp.wp_rec_start_date >= DATE '1999-01-01'
          AND wp.wp_type = 'article'
        GROUP BY wp.wp_customer_sk
    ) wp_cnt
        ON wp_cnt.wp_customer_sk = c.c_customer_sk
WHERE hd.hd_buy_potential = '>10000'
GROUP BY ib.ib_lower_bound, ib.ib_upper_bound
HAVING COUNT(DISTINCT c.c_customer_sk) > 5

UNION ALL

SELECT
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    COUNT(DISTINCT c.c_customer_sk),
    AVG(wp_cnt.page_cnt),
    (SELECT MAX(ib2.ib_upper_bound) FROM income_band ib2)
FROM
    birth_years byr
    JOIN customer c
        ON c.c_birth_year = byr.year
    JOIN household_demographics hd
        ON c.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN (
        SELECT wp.wp_customer_sk, COUNT(*) AS page_cnt
        FROM web_page wp
        WHERE wp.wp_rec_end_date IS NOT NULL
          AND wp.wp_url LIKE 'http://www.%'
        GROUP BY wp.wp_customer_sk
    ) wp_cnt
        ON wp_cnt.wp_customer_sk = c.c_customer_sk
WHERE hd.hd_buy_potential = '5001-10000'
GROUP BY ib.ib_lower_bound, ib.ib_upper_bound
HAVING COUNT(DISTINCT c.c_customer_sk) > 5

ORDER BY income_lower ASC
LIMIT 100
