/*
  Goal: Identify the top‑selling items per category where the item description contains a three‑digit number and the brand name starts with 'Brand'.
  The query aggregates sales, applies string pattern matching and extraction, ranks items within each category, and includes a correlated scalar subquery that counts promotions that started on the date of the item's most recent sale.
*/
WITH sales_agg AS (
    SELECT
        i.i_category,
        i.i_brand,
        i.i_item_id,
        i.i_item_desc,
        SUM(cs.cs_net_paid_inc_tax)                                           AS total_net_paid,
        SUM(cs.cs_quantity)                                                   AS total_quantity,
        AVG(cs.cs_sales_price)                                                AS avg_sales_price,
        COUNT(*)                                                              AS sales_count,
        MAX(d.d_date)                                                         AS last_sale_date,
        CONCAT(i.i_brand, ' ', i.i_item_desc)                                 AS brand_desc,
        regexp_extract(i.i_item_desc, '(\\d{3})', 1)                         AS three_digit_code,
        CASE WHEN regexp_like(i.i_item_desc, '[A-Z]{2}[0-9]{3}') THEN true ELSE false END AS desc_pattern_match
    FROM
        catalog_sales cs
        JOIN item i ON cs.cs_item_sk = i.i_item_sk
        JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE
        i.i_brand LIKE 'Brand%'
        AND regexp_like(i.i_item_desc, '.*[0-9]{3}.*')
    GROUP BY
        i.i_category,
        i.i_brand,
        i.i_item_id,
        i.i_item_desc
    HAVING
        SUM(cs.cs_net_paid_inc_tax) > 10000
)
SELECT
    s.i_category,
    s.i_brand,
    s.i_item_id,
    s.i_item_desc,
    s.total_net_paid,
    s.total_quantity,
    s.avg_sales_price,
    s.brand_desc,
    s.three_digit_code,
    s.desc_pattern_match,
    RANK() OVER (PARTITION BY s.i_category ORDER BY s.total_net_paid DESC) AS category_rank,
    (
        SELECT COUNT(*)
        FROM promotion p
        JOIN date_dim d2 ON p.p_start_date_sk = d2.d_date_sk
        WHERE p.p_item_sk = i.i_item_sk
          AND d2.d_date = s.last_sale_date
    ) AS promotions_on_last_sale
FROM
    sales_agg s
    JOIN item i ON s.i_item_id = i.i_item_id
ORDER BY
    s.total_net_paid DESC
LIMIT 100
