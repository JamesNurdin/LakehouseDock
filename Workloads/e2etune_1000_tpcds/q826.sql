WITH category_sales AS (
    SELECT
        i.i_category,
        i.i_brand,
        SUM(ss.ss_quantity) AS total_units,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_ext_discount_amt) AS total_discount,
        SUM(ss.ss_net_profit) AS total_profit,
        AVG(ss.ss_sales_price) AS avg_sales_price,
        AVG(ss.ss_ext_discount_amt / NULLIF(ss.ss_ext_sales_price, 0)) AS avg_discount_rate
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    WHERE ss.ss_sold_date_sk BETWEEN 2450000 AND 2451500
      AND i.i_class = 'Electronics'
      AND hd.hd_buy_potential = 'High'
    GROUP BY i.i_category, i.i_brand
    HAVING SUM(ss.ss_ext_sales_price) > 100000
)
SELECT
    i_category,
    i_brand,
    total_units,
    total_sales,
    total_discount,
    total_profit,
    avg_sales_price,
    avg_discount_rate,
    (total_profit / total_sales) * 100 AS profit_margin_pct,
    RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
FROM category_sales
ORDER BY total_sales DESC
LIMIT 30
