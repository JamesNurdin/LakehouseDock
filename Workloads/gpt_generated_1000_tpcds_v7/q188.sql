WITH returns_sales AS (
    SELECT
        cr.cr_order_number,
        cr.cr_return_amount,
        cs.cs_net_profit,
        hd.hd_income_band_sk,
        hd.hd_buy_potential,
        hd.hd_dep_count
    FROM catalog_returns cr
    JOIN catalog_sales cs
        ON cr.cr_order_number = cs.cs_order_number
       AND cr.cr_item_sk = cs.cs_item_sk
    JOIN household_demographics hd
        ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    WHERE regexp_like(hd.hd_buy_potential, '^M.*')
)
SELECT
    hd_income_band_sk,
    hd_buy_potential,
    COUNT(DISTINCT cr_order_number) AS distinct_orders,
    SUM(cr_return_amount) AS total_return_amount,
    SUM(cs_net_profit) AS total_net_profit,
    AVG(cs_net_profit) AS avg_net_profit,
    CONCAT('Band_', CAST(hd_income_band_sk AS VARCHAR)) AS income_band_label,
    REGEXP_EXTRACT(hd_buy_potential, '(\\w+)$') AS buy_potential_suffix
FROM returns_sales
GROUP BY
    hd_income_band_sk,
    hd_buy_potential,
    CONCAT('Band_', CAST(hd_income_band_sk AS VARCHAR)),
    REGEXP_EXTRACT(hd_buy_potential, '(\\w+)$')
ORDER BY total_return_amount DESC
LIMIT 100
