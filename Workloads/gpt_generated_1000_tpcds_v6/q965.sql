WITH returned_sales AS (
    SELECT
        cr.cr_order_number,
        cr.cr_return_amount,
        cr.cr_return_quantity,
        cr.cr_returned_date_sk,
        cr.cr_item_sk,
        cr.cr_refunded_cdemo_sk,
        cr.cr_returning_cdemo_sk,
        cs.cs_sold_date_sk,
        cs.cs_ext_sales_price,
        cs.cs_quantity,
        cs.cs_net_profit,
        i.i_category,
        i.i_item_desc,
        i.i_product_name,
        i.i_color,
        d_return.d_year AS return_year,
        d_sold.d_year AS sold_year,
        CASE WHEN regexp_like(i.i_item_desc, '(?i)premium') THEN 1 ELSE 0 END AS is_premium
    FROM catalog_returns cr
    JOIN catalog_sales cs
        ON cr.cr_order_number = cs.cs_order_number
       AND cr.cr_item_sk = cs.cs_item_sk
    JOIN item i
        ON cr.cr_item_sk = i.i_item_sk
    JOIN date_dim d_return
        ON cr.cr_returned_date_sk = d_return.d_date_sk
    JOIN date_dim d_sold
        ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN customer_demographics cd_ref
        ON cr.cr_refunded_cdemo_sk = cd_ref.cd_demo_sk
    WHERE regexp_like(i.i_product_name, '^.*[0-9]{3}.*$')
      AND i.i_color LIKE 'Red%'
),
agg AS (
    SELECT
        i_category,
        is_premium,
        i_product_name,
        COUNT(*) AS num_returns,
        SUM(cr_return_amount) AS total_return_amount,
        AVG(cs_net_profit) AS avg_net_profit
    FROM returned_sales
    GROUP BY i_category, is_premium, i_product_name
    HAVING COUNT(*) > 5
)
SELECT
    a.i_category,
    a.is_premium,
    a.i_product_name,
    a.num_returns,
    a.total_return_amount,
    a.avg_net_profit,
    RANK() OVER (PARTITION BY a.is_premium ORDER BY a.total_return_amount DESC) AS category_rank,
    CASE WHEN a.total_return_amount > 10000 THEN 'HIGH' ELSE 'LOW' END AS loss_level,
    substring(a.i_product_name, 1, 3) AS product_prefix,
    regexp_extract(a.i_product_name, '([0-9]{3})', 1) AS product_code,
    concat(a.i_category, '-', CAST(a.is_premium AS VARCHAR)) AS category_premium_key
FROM agg a
ORDER BY a.total_return_amount DESC
LIMIT 100
