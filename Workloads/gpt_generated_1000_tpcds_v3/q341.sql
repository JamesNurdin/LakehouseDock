WITH sales AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_item_sk,
        cs.cs_order_number,
        cs.cs_net_paid,
        cs.cs_net_profit,
        cs.cs_promo_sk,
        i.i_category,
        i.i_item_desc,
        d.d_year,
        p.p_promo_name
    FROM
        catalog_sales cs
        JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
        JOIN item i ON cs.cs_item_sk = i.i_item_sk
        JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE
        regexp_like(i.i_item_desc, '\\d+[a-z]+')
        AND p.p_promo_name LIKE '%Discount%'
),
returns AS (
    SELECT
        cr.cr_order_number,
        cr.cr_item_sk,
        cr.cr_net_loss
    FROM
        catalog_returns cr
)
SELECT
    s.d_year,
    s.i_category,
    regexp_extract(s.i_item_desc, '(\\d+)', 1) AS item_number,
    concat(s.i_category, '-', regexp_extract(s.i_item_desc, '(\\d+)', 1)) AS category_number_key,
    sum(s.cs_net_paid) AS total_sales_amount,
    sum(s.cs_net_profit) AS total_sales_profit,
    sum(coalesce(r.cr_net_loss, 0)) AS total_return_loss,
    (sum(s.cs_net_paid) - sum(coalesce(r.cr_net_loss, 0))) AS net_sales_minus_returns
FROM
    sales s
    LEFT JOIN returns r
        ON s.cs_order_number = r.cr_order_number
        AND s.cs_item_sk = r.cr_item_sk
GROUP BY
    s.d_year,
    s.i_category,
    regexp_extract(s.i_item_desc, '(\\d+)', 1),
    concat(s.i_category, '-', regexp_extract(s.i_item_desc, '(\\d+)', 1))
ORDER BY
    net_sales_minus_returns DESC
LIMIT 100
