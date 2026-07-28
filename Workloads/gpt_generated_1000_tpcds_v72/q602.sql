WITH filtered_items AS (
    SELECT
        i_item_sk,
        i_product_name,
        i_container,
        regexp_extract(i_product_name, '(\\d{3,})') AS extracted_num,
        i_brand,
        i_category
    FROM item
    WHERE regexp_like(i_product_name, '^[A-Z]{2,}\\s\\d{3,}')
      AND i_container LIKE '%BOX%'
)
SELECT
    fi.i_brand,
    fi.i_category,
    CONCAT(fi.i_brand, ':', fi.i_category) AS brand_category,
    fi.extracted_num,
    SUM(cs.cs_ext_sales_price) AS total_sales,
    SUM(cs.cs_net_profit) AS total_profit,
    AVG(cs.cs_sales_price) AS avg_sales_price,
    COUNT(DISTINCT cs.cs_order_number) AS order_cnt
FROM catalog_sales cs
JOIN filtered_items fi
    ON cs.cs_item_sk = fi.i_item_sk
GROUP BY fi.i_brand, fi.i_category, fi.extracted_num
ORDER BY total_profit DESC
LIMIT 100
