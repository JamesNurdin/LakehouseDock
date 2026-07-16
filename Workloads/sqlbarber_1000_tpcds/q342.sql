SELECT CASE WHEN wp.wp_char_count > 1000 THEN 'large' ELSE 'small' END AS page_size_category,
       (wp.wp_link_count * 2) + wp.wp_image_count AS link_image_score,
       CASE WHEN dd.d_month_seq BETWEEN 1 AND 3 THEN 'Q1'
            WHEN dd.d_month_seq BETWEEN 4 AND 6 THEN 'Q2'
            WHEN dd.d_month_seq BETWEEN 7 AND 9 THEN 'Q3'
            ELSE 'Q4' END AS quarter_custom,
       dd.d_year,
       dd.d_month_seq
FROM web_page wp
JOIN date_dim dd ON wp.wp_creation_date_sk = dd.d_date_sk
WHERE dd.d_year = CAST(1926 AS integer)
  AND wp.wp_type = CAST('general                                           ' AS varchar)
