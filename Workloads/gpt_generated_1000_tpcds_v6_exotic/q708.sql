WITH high_price_items AS (
    SELECT i_item_sk,
           i_product_name,
           i_brand
    FROM   item
    WHERE  i_current_price > 100
)
SELECT
    s.s_store_name,
    substr(s.s_store_name, 1, 3) AS store_prefix,
    regexp_extract(i.i_product_name, '(\\w+)-\\d+', 1) AS product_code,
    i.i_brand,
    SUM(ss.ss_net_profit) AS total_net_profit,
    COUNT(*) AS sales_cnt
FROM   store_sales ss
JOIN   date_dim d               ON ss.ss_sold_date_sk = d.d_date_sk
JOIN   store s                  ON ss.ss_store_sk = s.s_store_sk
JOIN   item i                   ON ss.ss_item_sk = i.i_item_sk
JOIN   high_price_items hpi    ON ss.ss_item_sk = hpi.i_item_sk
WHERE  d.d_year = 2000
  AND  s.s_store_name LIKE 'A%'
  AND  regexp_like(i.i_product_name, '^.*[A-Z]{2}[0-9]{2}.*$')
  AND  i.i_brand IN (
        SELECT DISTINCT i_brand
        FROM   item
        WHERE  i_brand_id IN (10, 20, 30)
    )
GROUP BY
    s.s_store_name,
    substr(s.s_store_name, 1, 3),
    regexp_extract(i.i_product_name, '(\\w+)-\\d+', 1),
    i.i_brand
ORDER BY total_net_profit DESC
LIMIT 100
