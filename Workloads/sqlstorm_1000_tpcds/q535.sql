SELECT
    d_year,
    s_store_name,
    i_category,
    i_brand,
    total_sales,
    total_profit,
    total_quantity,
    RANK() OVER (PARTITION BY d_year ORDER BY total_sales DESC) AS sales_rank
FROM (
    SELECT
        d.d_year AS d_year,
        s.s_store_name AS s_store_name,
        i.i_category AS i_category,
        i.i_brand AS i_brand,
        SUM(ss.ss_sales_price) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit,
        SUM(ss.ss_quantity) AS total_quantity
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 1999 AND 2001
      AND s.s_state = 'TX'
      AND i.i_brand = 'Brand#12'
    GROUP BY d.d_year, s.s_store_name, i.i_category, i.i_brand
    HAVING SUM(ss.ss_sales_price) > 100000
) t
ORDER BY total_sales DESC
LIMIT 50
