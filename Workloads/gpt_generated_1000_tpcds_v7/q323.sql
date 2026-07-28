WITH filtered_sales AS (
    SELECT
        ss.ss_ticket_number,
        ss.ss_net_profit,
        ss.ss_cdemo_sk,
        ss.ss_hdemo_sk,
        ss.ss_promo_sk
    FROM store_sales ss
    JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN time_dim t
        ON ss.ss_sold_time_sk = t.t_time_sk
    WHERE regexp_like(p.p_promo_name, '(?i)discount')
      AND cd.cd_education_status LIKE 'Bachelors%'
      AND t.t_meal_time = 'Lunch'
)
SELECT
    ib.ib_income_band_sk,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    COUNT(DISTINCT fs.ss_ticket_number) AS order_count,
    SUM(fs.ss_net_profit) AS total_net_profit,
    MAX(regexp_extract(p.p_promo_id, '(\\d+)')) AS promo_numeric_id,
    MAX(CONCAT(p.p_promo_name, ' - ', cd.cd_gender)) AS promo_gender
FROM filtered_sales fs
JOIN promotion p
    ON fs.ss_promo_sk = p.p_promo_sk
JOIN customer_demographics cd
    ON fs.ss_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd
    ON fs.ss_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
GROUP BY
    ib.ib_income_band_sk,
    ib.ib_lower_bound,
    ib.ib_upper_bound
HAVING SUM(fs.ss_net_profit) > 0
ORDER BY total_net_profit DESC
LIMIT 20
