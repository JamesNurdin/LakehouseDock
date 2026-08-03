WITH filtered_sales AS (
    SELECT
        ss.ss_ticket_number,
        ss.ss_ext_sales_price,
        i.i_item_desc,
        i.i_product_name,
        i.i_current_price,
        i.i_brand,
        i.i_category,
        s.s_store_id,
        s.s_store_name,
        s.s_city
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    WHERE regexp_like(i.i_item_desc, '[A-Z]{3}')
      AND i.i_product_name LIKE '%Special%'
      AND i.i_current_price > (
          SELECT AVG(i2.i_current_price)
          FROM item i2
          WHERE i2.i_brand = 'Brand#2'
      )
      AND EXISTS (
          SELECT 1
          FROM store_returns sr
          WHERE sr.sr_ticket_number = ss.ss_ticket_number
            AND sr.sr_return_amt > 0
      )
),
agg_sales AS (
    SELECT
        MIN(s_store_id)        AS s_store_id,
        MIN(i_brand)           AS i_brand,
        i_category,
        MIN(regexp_extract(i_item_desc, '[A-Z]{3}', 1)) AS sample_code,
        MIN(CONCAT(s_store_name, ' - ', s_city))      AS store_desc,
        SUM(ss_ext_sales_price)                      AS total_sales,
        COUNT(*)                                     AS sales_cnt
    FROM filtered_sales
    GROUP BY GROUPING SETS (
        (s_store_id, i_brand),
        (i_category)
    )
)
SELECT
    s_store_id,
    i_brand,
    i_category,
    sample_code,
    store_desc,
    total_sales,
    sales_cnt,
    ROW_NUMBER() OVER (PARTITION BY s_store_id ORDER BY total_sales DESC) AS store_rank
FROM agg_sales
ORDER BY total_sales DESC
LIMIT 100
