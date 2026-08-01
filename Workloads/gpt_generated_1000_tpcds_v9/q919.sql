WITH filtered_sales AS (
    SELECT
        ss.ss_net_profit,
        ss.ss_ext_sales_price,
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        hd.hd_buy_potential,
        hd.hd_demo_sk,
        CAST(regexp_extract(hd.hd_buy_potential, '(\\d+)', 1) AS INTEGER) AS buy_potential_numeric,
        SUBSTRING(hd.hd_buy_potential FROM 1 FOR 1) AS buy_potential_prefix
    FROM store_sales ss
    JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE regexp_like(hd.hd_buy_potential, '^[0-9]+-')
      AND CAST(regexp_extract(hd.hd_buy_potential, '(\\d+)', 1) AS INTEGER) > 5000
      AND hd.hd_buy_potential LIKE '%-%'
)
SELECT
    CONCAT('Band ', CAST(fs.ib_income_band_sk AS varchar)) AS band_label,
    fs.ib_lower_bound,
    fs.ib_upper_bound,
    fs.hd_buy_potential,
    fs.buy_potential_numeric,
    fs.buy_potential_prefix,
    COUNT(*) AS total_transactions,
    SUM(fs.ss_net_profit) AS total_net_profit,
    AVG(fs.ss_net_profit) AS avg_net_profit,
    SUM(fs.ss_ext_sales_price) AS total_sales_amount,
    SUM(fs.ss_net_profit) / (SELECT SUM(ss2.ss_net_profit) FROM store_sales ss2) AS profit_share,
    CASE WHEN EXISTS (
            SELECT 1
            FROM store_sales ss2
            JOIN household_demographics hd2 ON ss2.ss_hdemo_sk = hd2.hd_demo_sk
            JOIN income_band ib2 ON hd2.hd_income_band_sk = ib2.ib_income_band_sk
            WHERE ib2.ib_income_band_sk = fs.ib_income_band_sk
              AND hd2.hd_buy_potential = fs.hd_buy_potential
              AND ss2.ss_net_profit > 1000
        )
        THEN 'YES' ELSE 'NO' END AS has_high_profit_txn
FROM filtered_sales fs
GROUP BY
    fs.ib_income_band_sk,
    fs.ib_lower_bound,
    fs.ib_upper_bound,
    fs.hd_buy_potential,
    fs.buy_potential_numeric,
    fs.buy_potential_prefix
ORDER BY total_net_profit DESC
LIMIT 100
