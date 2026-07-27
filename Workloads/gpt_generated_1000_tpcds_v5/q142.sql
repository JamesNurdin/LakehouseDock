WITH filtered_demo AS (
    SELECT DISTINCT
        hd_demo_sk,
        hd_income_band_sk,
        hd_buy_potential,
        regexp_extract(hd_buy_potential, '(\\d+)-(\\d+)', 1) AS lower_range,
        regexp_extract(hd_buy_potential, '(\\d+)-(\\d+)', 2) AS upper_range
    FROM household_demographics
    WHERE regexp_like(hd_buy_potential, '^[0-9]+-[0-9]+$')
      AND hd_buy_potential LIKE '%-%'
)
SELECT
    ib.ib_income_band_sk,
    fd.hd_buy_potential,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
    SUM(cs.cs_net_profit) AS total_net_profit,
    AVG(CAST(fd.lower_range AS integer)) AS avg_lower_range,
    MAX(CAST(fd.upper_range AS integer)) AS max_upper_range
FROM filtered_demo fd
JOIN catalog_sales cs
    ON cs.cs_bill_hdemo_sk = fd.hd_demo_sk
JOIN income_band ib
    ON fd.hd_income_band_sk = ib.ib_income_band_sk
WHERE cs.cs_net_paid_inc_tax > 1000
GROUP BY ib.ib_income_band_sk, fd.hd_buy_potential
ORDER BY total_net_profit DESC
LIMIT 100
