WITH item_word_exp AS (
   SELECT i.i_item_sk,
          word
   FROM   item i
   CROSS JOIN UNNEST(split(i.i_item_desc, ' ')) AS t(word)
   WHERE  i.i_item_desc IS NOT NULL
),
sales_summary AS (
   SELECT d_sold.d_year                         AS d_year,
          s.s_store_id,
          ws.web_site_id,
          i.i_item_sk,
          COUNT(*)                               AS sales_cnt,
          SUM(cs.cs_ext_sales_price)             AS sales_amount,
          AVG(cs.cs_net_profit)                  AS avg_profit,
          COUNT(DISTINCT c.c_customer_sk)        AS unique_customers,
          COUNT(DISTINCT w.word)                 AS distinct_words_in_item_desc
   FROM   catalog_sales cs
   JOIN   customer c
          ON cs.cs_bill_customer_sk = c.c_customer_sk
   JOIN   date_dim d_sold
          ON cs.cs_sold_date_sk = d_sold.d_date_sk
   JOIN   item i
          ON cs.cs_item_sk = i.i_item_sk
   LEFT JOIN item_word_exp w
          ON i.i_item_sk = w.i_item_sk
   JOIN   date_dim d_ship
          ON cs.cs_ship_date_sk = d_ship.d_date_sk
   JOIN   web_site ws
          ON ws.web_open_date_sk = d_ship.d_date_sk
          AND ws.web_country = 'US'
   RIGHT OUTER JOIN store s
          ON s.s_closed_date_sk = d_sold.d_date_sk
          AND s.s_state = 'CA'
   WHERE  d_sold.d_year BETWEEN 1908 AND 1914
     AND  i.i_current_price > 100
     AND  c.c_preferred_cust_flag = 'Y'
     AND  cs.cs_ext_sales_price > 500
     AND  cs.cs_item_sk IN (
            SELECT i2.i_item_sk FROM item i2 WHERE i2.i_brand = 'BrandX'
          )
   GROUP BY d_sold.d_year, s.s_store_id, ws.web_site_id, i.i_item_sk
)
SELECT   year,
         COUNT(*)                         AS num_items,
         AVG(sales_amount)                AS avg_sales_amount,
         SUM(sales_cnt)                   AS total_transactions,
         AVG(distinct_words_in_item_desc) AS avg_distinct_words
FROM (
   SELECT d_year            AS year,
          s_store_id,
          web_site_id,
          i_item_sk,
          sales_cnt,
          sales_amount,
          distinct_words_in_item_desc
   FROM   sales_summary
   WHERE  sales_amount > (
            SELECT MAX(d2.d_year)
            FROM   date_dim d2
            WHERE  d2.d_year < 1915
          )
) agg
GROUP BY year
HAVING COUNT(*) > 10
ORDER BY avg_sales_amount DESC
LIMIT 100
