/*
Goal: Identify stores whose names contain the word "Market" and that have no recorded "Damaged" returns. For each store and sales year, compute total sales, discounts, profit and categorize each transaction by discount level. Extract a three‑letter code from the item description using regex, and also show the first five characters of the description. Limit to the top 100 rows by profit.
*/
SELECT
  s.s_store_id,
  s.s_store_name,
  d.d_year,
  regexp_extract(i.i_item_desc, '(\\w{3})', 1)               AS three_letter_code,
  substring(i.i_item_desc FROM 1 FOR 5)                     AS item_prefix,
  CASE
    WHEN ss.ss_ext_discount_amt > 0.2 * ss.ss_ext_list_price THEN 'High Discount'
    ELSE 'Normal Discount'
  END                                                       AS discount_category,
  SUM(ss.ss_ext_sales_price)                               AS total_sales,
  SUM(ss.ss_ext_discount_amt)                              AS total_discount,
  SUM(ss.ss_net_profit)                                    AS total_profit,
  COUNT(*)                                                  AS transaction_count
FROM store_sales ss
JOIN store s
  ON ss.ss_store_sk = s.s_store_sk
JOIN date_dim d
  ON ss.ss_sold_date_sk = d.d_date_sk
JOIN item i
  ON ss.ss_item_sk = i.i_item_sk
WHERE s.s_store_name LIKE '%Market%'
  AND regexp_like(i.i_item_desc, '[A-Z]{3}')
  AND NOT EXISTS (
        SELECT 1
        FROM store_returns sr
        JOIN reason r
          ON sr.sr_reason_sk = r.r_reason_sk
        WHERE sr.sr_store_sk = s.s_store_sk
          AND r.r_reason_desc = 'Damaged'
      )
GROUP BY
  s.s_store_id,
  s.s_store_name,
  d.d_year,
  regexp_extract(i.i_item_desc, '(\\w{3})', 1),
  substring(i.i_item_desc FROM 1 FOR 5),
  CASE
    WHEN ss.ss_ext_discount_amt > 0.2 * ss.ss_ext_list_price THEN 'High Discount'
    ELSE 'Normal Discount'
  END
ORDER BY total_profit DESC
LIMIT 100
