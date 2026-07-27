WITH filtered_items AS (
    SELECT
        i_item_sk,
        i_item_desc,
        i_product_name,
        i_color,
        i_units,
        i_container,
        regexp_extract(i_item_desc, '(\\d{3})') AS extracted_code,
        concat(i_color, '-', i_units) AS color_units
    FROM item
    WHERE regexp_like(i_item_desc, '^[A-Za-z]+\\s\\d{3}')
      AND i_units LIKE '%Lb%'
)
SELECT
    di.d_year,
    fi.i_product_name,
    fi.color_units,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    COUNT(DISTINCT ss.ss_ticket_number) AS distinct_tickets,
    ROW_NUMBER() OVER (PARTITION BY di.d_year ORDER BY SUM(ss.ss_ext_sales_price) DESC) AS sales_rank
FROM filtered_items fi
JOIN store_sales ss
    ON ss.ss_item_sk = fi.i_item_sk
JOIN date_dim di
    ON ss.ss_sold_date_sk = di.d_date_sk
WHERE di.d_year BETWEEN 2000 AND 2002
GROUP BY di.d_year, fi.i_product_name, fi.color_units
HAVING SUM(ss.ss_ext_sales_price) > 10000
ORDER BY total_sales DESC
LIMIT 100
