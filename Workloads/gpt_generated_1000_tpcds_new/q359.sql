WITH sampled_sales AS (
    SELECT *
    FROM store_sales
    TABLESAMPLE BERNOULLI (5)
),
joined AS (
    SELECT
        ss.ss_ticket_number,
        ss.ss_net_profit,
        ss.ss_sold_date_sk,
        d.d_year,
        d.d_month_seq,
        p.p_promo_name,
        hd.hd_buy_potential,
        regexp_extract(p.p_promo_name, '(\\d+)', 1) AS promo_digits,
        CASE
            WHEN regexp_like(p.p_promo_name, '^PROMO[0-9]{3}$') THEN 'standard'
            ELSE 'other'
        END AS promo_type,
        concat(CAST(d.d_year AS varchar), '-', lpad(CAST(((d.d_month_seq - 1) % 12) + 1 AS varchar), 2, '0')) AS year_month,
        substring(hd.hd_buy_potential, 1, 5) AS buy_pot_prefix
    FROM sampled_sales ss
    FULL OUTER JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    LEFT JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    LEFT JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
)
SELECT
    year_month,
    promo_type,
    COUNT(DISTINCT ss_ticket_number) AS orders,
    SUM(ss_net_profit) AS total_profit,
    AVG(CAST(promo_digits AS double)) AS avg_promo_number
FROM joined
WHERE p_promo_name LIKE '%PROMO%'
  AND buy_pot_prefix = 'high'
GROUP BY year_month, promo_type
ORDER BY total_profit DESC
OFFSET 20 ROWS
LIMIT 100
