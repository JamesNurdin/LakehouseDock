WITH sampled_sales AS (
    SELECT *
    FROM store_sales TABLESAMPLE BERNOULLI (10)
)
SELECT
    d.d_year,
    i.i_category,
    i.i_brand,
    i.i_item_sk,
    i.i_product_name,
    CONCAT(i.i_brand, ' - ', i.i_category) AS brand_category,
    SUBSTRING(i.i_product_name, 1, 4) AS product_prefix,
    REGEXP_EXTRACT(i.i_product_name, '([A-Z]+[0-9]+)', 1) AS product_code,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    SUM(ss.ss_quantity) AS total_quantity,
    MAX(ss.ss_net_profit) AS max_net_profit,
    MIN(ib.ib_lower_bound) AS income_lower_bound,
    MAX(ib.ib_upper_bound) AS income_upper_bound,
    (
        SELECT SUM(ss_all.ss_ext_sales_price)
        FROM store_sales ss_all
        WHERE ss_all.ss_item_sk = i.i_item_sk
    ) AS total_sales_all_years,
    (
        SELECT COUNT(*)
        FROM store_returns sr_all
        JOIN date_dim d2 ON sr_all.sr_returned_date_sk = d2.d_date_sk
        WHERE sr_all.sr_item_sk = i.i_item_sk
          AND d2.d_year = d.d_year
    ) AS returns_in_year
FROM sampled_sales ss
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
JOIN item i ON ss.ss_item_sk = i.i_item_sk
JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
WHERE
    REGEXP_LIKE(i.i_item_desc, '\\d{3}')
    AND i.i_brand LIKE 'Brand%'
    AND CONCAT(i.i_brand, '-', i.i_category) LIKE 'Brand%-%'
    AND t.t_meal_time = 'Dinner'
    AND NOT EXISTS (
        SELECT 1
        FROM store_returns sr
        WHERE sr.sr_ticket_number = ss.ss_ticket_number
          AND sr.sr_item_sk = ss.ss_item_sk
    )
GROUP BY ROLLUP (d.d_year, i.i_category, i.i_brand, i.i_item_sk, i.i_product_name)
HAVING SUM(ss.ss_ext_sales_price) > 500
ORDER BY total_sales DESC
LIMIT 100
