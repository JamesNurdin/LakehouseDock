WITH sales AS (
    SELECT ss.*, d.d_year, d.d_month_seq,
           c.c_first_name, c.c_last_name, c.c_email_address,
           i.i_item_desc, i.i_product_name, i.i_color, i.i_size
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 1999 AND 2001
),
prepared AS (
    SELECT s.d_year,
           s.d_month_seq,
           concat_ws(' ',
               lower(trim(s.c_first_name)),
               lower(trim(s.c_last_name)),
               lower(regexp_replace(trim(s.c_email_address), '@.*', '')),
               lower(regexp_replace(trim(s.i_item_desc), '[^a-zA-Z0-9 ]', '')),
               lower(regexp_replace(trim(s.i_product_name), '[^a-zA-Z0-9 ]', '')),
               lower(s.i_color),
               lower(s.i_size)
           ) AS composite_str
    FROM sales s
)
SELECT p.d_year,
       p.d_month_seq,
       COUNT(*) AS sales_cnt,
       AVG(length(p.composite_str)) AS avg_len,
       AVG(cardinality(regexp_split(p.composite_str, '\\s+'))) AS avg_word_cnt,
       AVG(length(regexp_replace(p.composite_str, '(?i)[^aeiou]', ''))) AS avg_vowel_cnt,
       AVG(length(p.composite_str) - length(regexp_replace(p.composite_str, 'a', ''))) AS avg_a_cnt,
       AVG(length(p.composite_str) - length(regexp_replace(p.composite_str, 'e', ''))) AS avg_e_cnt,
       SUM(CASE WHEN lower(regexp_replace(p.composite_str, '\\s+', '')) = reverse(lower(regexp_replace(p.composite_str, '\\s+', ''))) THEN 1 ELSE 0 END) AS palindrome_cnt
FROM prepared p
GROUP BY p.d_year, p.d_month_seq
ORDER BY p.d_year, p.d_month_seq
