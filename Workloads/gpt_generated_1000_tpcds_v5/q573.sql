WITH sales AS (
    SELECT
        i.i_item_sk,
        i.i_class,
        i.i_brand,
        i.i_product_name,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit
    FROM store_sales ss
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    WHERE i.i_product_name LIKE '%Pro%'
      AND regexp_like(i.i_item_desc, '.*[A-Z]{2}.*')
    GROUP BY
        i.i_item_sk,
        i.i_class,
        i.i_brand,
        i.i_product_name
),
returns AS (
    SELECT
        i.i_item_sk,
        SUM(sr.sr_return_amt) AS total_return_amount,
        SUM(sr.sr_net_loss) AS total_return_loss
    FROM store_returns sr
    JOIN item i
        ON sr.sr_item_sk = i.i_item_sk
    WHERE sr.sr_store_credit > 10
      AND i.i_size = 'small'
      AND regexp_like(i.i_item_id, '^A[0-9]{3}$')
    GROUP BY i.i_item_sk
),
catalog AS (
    SELECT
        cr.cr_item_sk,
        SUM(cr.cr_net_loss) AS total_catalog_loss
    FROM catalog_returns cr
    GROUP BY cr.cr_item_sk
)
SELECT
    s.i_class,
    CONCAT(s.i_brand, ' ', s.i_product_name) AS brand_product,
    s.total_sales,
    s.total_profit,
    COALESCE(r.total_return_amount, 0) AS total_return_amount,
    COALESCE(r.total_return_loss, 0) AS total_return_loss,
    COALESCE(c.total_catalog_loss, 0) AS total_catalog_loss,
    (s.total_sales - COALESCE(r.total_return_amount, 0) - COALESCE(c.total_catalog_loss, 0)) AS net_revenue
FROM sales s
LEFT JOIN returns r
    ON s.i_item_sk = r.i_item_sk
LEFT JOIN catalog c
    ON s.i_item_sk = c.cr_item_sk
WHERE s.total_sales > 1000
ORDER BY net_revenue DESC
LIMIT 100
