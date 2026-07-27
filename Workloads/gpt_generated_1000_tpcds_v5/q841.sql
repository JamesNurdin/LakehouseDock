WITH first_part AS (
    SELECT
        s.s_store_name,
        SUM(ss.ss_net_paid) AS total_net_paid,
        CASE WHEN SUM(ss.ss_net_profit) > 10000 THEN 'High' ELSE 'Low' END AS profit_category
    FROM
        store_sales ss
        JOIN store s ON ss.ss_store_sk = s.s_store_sk
        JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
        JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
        JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
        JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE
        cd.cd_credit_rating = 'Good'
        AND ib.ib_lower_bound > 50000
    GROUP BY
        s.s_store_name
),
second_part AS (
    SELECT
        s.s_store_name,
        SUM(ss.ss_net_paid) AS total_net_paid,
        CASE WHEN SUM(ss.ss_net_profit) > 10000 THEN 'High' ELSE 'Low' END AS profit_category
    FROM
        store_sales ss
        JOIN store s ON ss.ss_store_sk = s.s_store_sk
        JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
        JOIN web_page wp ON wp.wp_customer_sk = c.c_customer_sk
        JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
        JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE
        wp.wp_max_ad_count > 2
        AND ib.ib_upper_bound <= 80000
    GROUP BY
        s.s_store_name
)
SELECT
    combined.s_store_name,
    combined.total_net_paid,
    combined.profit_category
FROM (
    SELECT * FROM first_part
    UNION ALL
    SELECT * FROM second_part
) AS combined
ORDER BY
    combined.total_net_paid DESC
LIMIT 100
