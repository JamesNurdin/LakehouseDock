WITH filtered_items AS (
    SELECT i_item_sk,
           i_product_name,
           i_item_desc,
           i_brand,
           i_category
    FROM tpcds.item
    WHERE regexp_like(i_product_name, '[0-9]{3}')
      AND i_item_desc LIKE '%steel%'
)
SELECT
    concat(s.s_store_name, ' (', s.s_city, ')') AS store_full_name,
    substring(s.s_store_name FROM 1 FOR 5) AS store_prefix,
    d.d_year,
    COUNT(DISTINCT ss.ss_ticket_number) AS total_transactions,
    SUM(ss.ss_net_profit) AS total_net_profit,
    AVG(ss.ss_sales_price) AS avg_sales_price,
    regexp_extract(i.i_item_desc, '(\\w+\\s\\w+)', 1) AS extracted_phrase
FROM tpcds.store_sales ss
JOIN tpcds.date_dim d
  ON ss.ss_sold_date_sk = d.d_date_sk
JOIN tpcds.store s
  ON ss.ss_store_sk = s.s_store_sk
JOIN filtered_items i
  ON ss.ss_item_sk = i.i_item_sk
WHERE s.s_state = 'CA'
  AND d.d_year BETWEEN 2001 AND 2002
  AND regexp_like(s.s_store_name, '^Store.*')
  AND EXISTS (
        SELECT 1
        FROM tpcds.call_center cc
        JOIN tpcds.date_dim d_cc
          ON cc.cc_closed_date_sk = d_cc.d_date_sk
        WHERE cc.cc_state = s.s_state
          AND d_cc.d_year = d.d_year
          AND cc.cc_name LIKE 'Call%'
    )
GROUP BY
    concat(s.s_store_name, ' (', s.s_city, ')'),
    substring(s.s_store_name FROM 1 FOR 5),
    d.d_year,
    regexp_extract(i.i_item_desc, '(\\w+\\s\\w+)', 1)
HAVING SUM(ss.ss_net_profit) > 10000
ORDER BY total_net_profit DESC
LIMIT 100
