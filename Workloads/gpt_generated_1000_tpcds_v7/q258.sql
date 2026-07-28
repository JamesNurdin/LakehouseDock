WITH filtered_sales AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_net_paid,
        cs.cs_ext_discount_amt,
        cs.cs_order_number,
        i.i_item_desc,
        i.i_brand,
        i.i_product_name,
        p.p_promo_name,
        d.d_date,
        d.d_year,
        d.d_month_seq
    FROM tpcds.catalog_sales cs
    INNER JOIN tpcds.item i
        ON cs.cs_item_sk = i.i_item_sk
    INNER JOIN tpcds.promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    INNER JOIN tpcds.date_dim d
        ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_date BETWEEN DATE '2022-01-01' AND DATE '2022-12-31'
      AND regexp_like(i.i_item_desc, '(?i)color')
      AND p.p_promo_name LIKE 'Summer%'
)
SELECT
    d_year,
    d_month_seq,
    sum(cs_net_paid)                        AS total_net_paid,
    avg(cs_ext_discount_amt)                AS avg_discount,
    count(DISTINCT cs_order_number)         AS distinct_orders,
    concat(i_brand, ' ', i_product_name)    AS product_label,
    regexp_extract(i_item_desc, '(?i)color[:\s]+([A-Za-z0-9]+)', 1) AS color_code,
    substr(i_item_desc, 1, 30)              AS short_desc
FROM filtered_sales
GROUP BY
    d_year,
    d_month_seq,
    i_brand,
    i_product_name,
    i_item_desc
ORDER BY total_net_paid DESC
LIMIT 100
