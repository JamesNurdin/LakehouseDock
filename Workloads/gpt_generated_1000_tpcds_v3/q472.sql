WITH filtered_items AS (
    SELECT
        i.i_item_sk,
        i.i_brand,
        i.i_product_name,
        i.i_item_desc,
        regexp_extract(i.i_item_desc, '(\\d{3,})') AS numeric_code,
        CASE WHEN regexp_like(i.i_item_desc, '\\d{3,}') THEN true ELSE false END AS has_numeric_code
    FROM tpcds.item i
    WHERE regexp_like(i.i_item_desc, '\\d{3,}')
      AND i.i_brand LIKE 'B%'
)
SELECT
    concat(s.s_store_name, ' - ', s.s_city) AS store_location,
    substring(fi.i_product_name, 1, 15) AS product_prefix,
    fi.numeric_code,
    sum(ss.ss_net_profit) AS total_net_profit,
    count(*) AS sales_transactions,
    (
        SELECT avg(cs.cs_net_paid_inc_tax)
        FROM tpcds.catalog_sales cs
        WHERE cs.cs_item_sk = fi.i_item_sk
          AND cs.cs_net_paid_inc_tax > 0
    ) AS avg_catalog_sales_paid
FROM tpcds.store_sales ss
JOIN filtered_items fi ON ss.ss_item_sk = fi.i_item_sk
JOIN tpcds.store s ON ss.ss_store_sk = s.s_store_sk
JOIN tpcds.time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
WHERE EXISTS (
    SELECT 1
    FROM tpcds.catalog_sales cs2
    WHERE cs2.cs_item_sk = fi.i_item_sk
      AND cs2.cs_net_paid_inc_tax > 5000
)
  AND s.s_store_name LIKE '%Market%'
GROUP BY
    s.s_store_name,
    s.s_city,
    substring(fi.i_product_name, 1, 15),
    fi.numeric_code,
    fi.i_item_sk
ORDER BY total_net_profit DESC
LIMIT 100
