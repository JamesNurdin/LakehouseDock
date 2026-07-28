WITH sales_filtered AS (
    SELECT
        i.i_brand,
        hd.hd_buy_potential,
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        ss.ss_ext_sales_price,
        ss.ss_quantity,
        -- extract the first three alphabetic characters from the description
        regexp_extract(i.i_item_desc, '^([A-Za-z]{3})', 1) AS item_prefix,
        -- concatenate brand and buy‑potential for later use
        CONCAT(i.i_brand, '-', hd.hd_buy_potential) AS brand_buy
    FROM store_sales ss
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE i.i_item_desc LIKE '%UG%'
      AND regexp_like(i.i_item_desc, '[0-9]{2,}')
      AND i.i_current_price > 20
)
SELECT
    i_brand,
    hd_buy_potential,
    ib_income_band_sk,
    CONCAT(i_brand, '-', hd_buy_potential) AS brand_buy,
    SUBSTRING(i_brand, 1, 3) AS brand_prefix,
    SUM(ss_ext_sales_price)          AS total_sales,
    SUM(ss_quantity)                 AS total_quantity,
    COUNT(*)                         AS transaction_count,
    MIN(ib_lower_bound)              AS income_lower,
    MAX(ib_upper_bound)              AS income_upper
FROM sales_filtered
GROUP BY ROLLUP (i_brand, hd_buy_potential, ib_income_band_sk)
ORDER BY i_brand ASC NULLS FIRST,
         hd_buy_potential ASC NULLS FIRST,
         ib_income_band_sk ASC NULLS FIRST
LIMIT 100
