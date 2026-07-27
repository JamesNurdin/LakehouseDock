WITH sales_data AS (
    SELECT
        cs.cs_order_number,
        cs.cs_net_paid_inc_tax,
        cs.cs_sold_time_sk,
        i.i_item_desc,
        i.i_brand,
        i.i_color,
        substr(i.i_item_desc, 1, 10) AS short_desc,
        regexp_extract(i.i_item_desc, '([A-Za-z]+)', 1) AS first_word,
        concat(i.i_brand, '-', i.i_color) AS brand_color,
        CASE
            WHEN cs.cs_net_paid_inc_tax >= 5000 THEN 'VIP'
            WHEN cs.cs_net_paid_inc_tax >= 1000 THEN 'High'
            ELSE 'Low'
        END AS sales_tier,
        r.r_reason_desc,
        td.t_hour
    FROM tpcds.catalog_sales cs
    JOIN tpcds.item i
        ON cs.cs_item_sk = i.i_item_sk
    LEFT JOIN tpcds.catalog_returns cr
        ON cs.cs_order_number = cr.cr_order_number
    LEFT JOIN tpcds.reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    JOIN tpcds.time_dim td
        ON cs.cs_sold_time_sk = td.t_time_sk
    WHERE regexp_like(i.i_item_desc, '\\b[A-Z]{3}\\b')
      AND r.r_reason_desc LIKE '%not%'
      AND td.t_hour BETWEEN 9 AND 17
)
SELECT
    brand_color,
    short_desc,
    first_word,
    sales_tier,
    SUM(cs_net_paid_inc_tax) AS total_net_paid,
    COUNT(*) AS transaction_cnt
FROM sales_data
GROUP BY brand_color, short_desc, first_word, sales_tier
ORDER BY total_net_paid DESC
LIMIT 100
