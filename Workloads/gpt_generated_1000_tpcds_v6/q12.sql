WITH filtered_sales AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_item_sk,
        ss.ss_cdemo_sk,
        ss.ss_store_sk,
        ss.ss_quantity,
        ss.ss_ext_sales_price,
        ss.ss_ext_discount_amt,
        ss.ss_net_profit
    FROM store_sales ss
    WHERE ss.ss_quantity >= 10
        AND ss.ss_ext_discount_amt > 50
        AND ss.ss_net_profit > 0
)
SELECT
    d.d_year,
    i.i_category,
    SUM(fs.ss_ext_sales_price) AS total_sales,
    AVG(fs.ss_ext_discount_amt) AS avg_discount,
    COUNT(DISTINCT fs.ss_store_sk) AS store_count,
    MIN(fs.ss_net_profit) AS min_profit,
    MAX(fs.ss_net_profit) AS max_profit,
    RANK() OVER (PARTITION BY d.d_year ORDER BY SUM(fs.ss_ext_sales_price) DESC) AS sales_rank
FROM filtered_sales fs
JOIN date_dim d
    ON fs.ss_sold_date_sk = d.d_date_sk
JOIN item i
    ON fs.ss_item_sk = i.i_item_sk
JOIN customer_demographics cd
    ON fs.ss_cdemo_sk = cd.cd_demo_sk
WHERE d.d_year BETWEEN 1999 AND 2001
    AND i.i_category_id IN (2, 3, 6, 9)
    AND i.i_current_price BETWEEN 5 AND 100
    AND cd.cd_marital_status = 'M'
    AND cd.cd_dep_employed_count <= 3
GROUP BY d.d_year, i.i_category
ORDER BY total_sales DESC
LIMIT 100
