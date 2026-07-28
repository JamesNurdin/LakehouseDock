WITH sales_agg AS (
    SELECT
        s.s_store_sk AS store_sk,
        s.s_city,
        s.s_street_name,
        hd.hd_income_band_sk,
        SUM(ss.ss_net_paid) AS total_net_paid,
        SUM(ss.ss_net_profit) AS total_net_profit,
        COUNT(*) AS sales_cnt
    FROM store_sales ss
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    WHERE REGEXP_LIKE(s.s_market_desc, 'children')
      AND s.s_city LIKE 'S%'
    GROUP BY s.s_store_sk, s.s_city, s.s_street_name, hd.hd_income_band_sk
)
SELECT
    sa.s_city,
    sa.s_street_name,
    CONCAT(sa.s_city, ' ', sa.s_street_name) AS full_location,
    REGEXP_EXTRACT(sa.s_street_name, '(\\d+)', 1) AS street_number,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    sa.total_net_paid,
    sa.total_net_profit,
    (SELECT AVG(total_net_profit) FROM sales_agg) AS avg_net_profit_all,
    EXISTS (
        SELECT 1
        FROM store_returns sr
        WHERE sr.sr_store_sk = sa.store_sk
          AND sr.sr_return_quantity > 10
    ) AS has_large_returns
FROM sales_agg sa
JOIN income_band ib
    ON sa.hd_income_band_sk = ib.ib_income_band_sk
WHERE ib.ib_lower_bound >= 50000
ORDER BY sa.total_net_profit DESC
LIMIT 100
