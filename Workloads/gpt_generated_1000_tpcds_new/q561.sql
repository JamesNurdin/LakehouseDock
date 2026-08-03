WITH base AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_returned_time_sk,
        cr.cr_item_sk,
        cr.cr_catalog_page_sk,
        cr.cr_refunded_customer_sk,
        cr.cr_return_quantity,
        cr.cr_return_amount,
        cr.cr_return_tax,
        cr.cr_fee,
        cr.cr_return_ship_cost,
        i.i_brand,
        i.i_category,
        cp.cp_department,
        d.d_year,
        t.t_hour,
        c.c_birth_month,
        wp.wp_type,
        wp.wp_url
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN web_page wp ON wp.wp_customer_sk = c.c_customer_sk
    WHERE d.d_year = 2001
      AND t.t_hour BETWEEN 9 AND 17
      AND i.i_brand = 'BrandX'
      AND cp.cp_department = 'Women'
      AND wp.wp_type = 'Product'
      AND c.c_birth_month = 7
),
inv_join AS (
    SELECT
        b.*, 
        inv.inv_quantity_on_hand
    FROM base b
    JOIN inventory inv 
        ON inv.inv_date_sk = b.cr_returned_date_sk
       AND inv.inv_item_sk = b.cr_item_sk
),
agg1 AS (
    SELECT
        b.cr_refunded_customer_sk AS cust_sk,
        b.c_birth_month,
        b.i_brand,
        SUM(b.cr_return_amount) AS total_return_amount,
        AVG(b.cr_return_quantity) AS avg_return_qty,
        COUNT(DISTINCT b.cr_item_sk) AS distinct_items,
        SUM(b.inv_quantity_on_hand) AS total_on_hand,
        MIN(b.wp_url) AS sample_url
    FROM inv_join b
    GROUP BY b.cr_refunded_customer_sk, b.c_birth_month, b.i_brand
),
agg2 AS (
    SELECT
        b.cr_refunded_customer_sk AS cust_sk,
        b.c_birth_month,
        b.i_brand,
        SUM(b.cr_return_amount) * 0.9 AS total_return_amount,
        AVG(b.cr_return_quantity) AS avg_return_qty,
        COUNT(DISTINCT b.cr_item_sk) AS distinct_items,
        SUM(b.inv_quantity_on_hand) * 0.9 AS total_on_hand,
        MIN(b.wp_url) AS sample_url
    FROM inv_join b
    WHERE b.cr_return_tax > 0
    GROUP BY b.cr_refunded_customer_sk, b.c_birth_month, b.i_brand
),
union_agg AS (
    SELECT * FROM agg1
    UNION DISTINCT
    SELECT * FROM agg2
),
high_return_customers AS (
    SELECT cr.cr_refunded_customer_sk AS cust_sk
    FROM catalog_returns cr
    WHERE cr.cr_return_amount > 5000
    GROUP BY cr.cr_refunded_customer_sk
    HAVING COUNT(*) > 10
),
low_return_customers AS (
    SELECT cr.cr_refunded_customer_sk AS cust_sk
    FROM catalog_returns cr
    WHERE cr.cr_return_amount < 100
    GROUP BY cr.cr_refunded_customer_sk
    HAVING COUNT(*) > 20
),
final_customers AS (
    SELECT cust_sk FROM high_return_customers
    EXCEPT
    SELECT cust_sk FROM low_return_customers
)
SELECT
    ua.cust_sk,
    ua.c_birth_month,
    ua.i_brand,
    ua.total_return_amount,
    ua.avg_return_qty,
    ua.distinct_items,
    ua.total_on_hand,
    part AS url_segment
FROM (
    SELECT a.*
    FROM union_agg a
    JOIN final_customers fc ON a.cust_sk = fc.cust_sk
) ua
CROSS JOIN UNNEST(split(ua.sample_url, '/')) AS t(part)
ORDER BY ua.total_return_amount DESC
OFFSET 0 ROWS FETCH NEXT 50 ROWS ONLY
