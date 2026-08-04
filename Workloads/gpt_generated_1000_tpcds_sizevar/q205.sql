WITH base AS (
    SELECT
        ss.ss_item_sk,
        ss.ss_ext_sales_price,
        cr.cr_return_amount,
        i1.i_brand,
        p.p_promo_id,
        cp.cp_department
    FROM store_sales ss
    JOIN item i1
        ON ss.ss_item_sk = i1.i_item_sk                           -- join 1
    JOIN household_demographics hd_sales
        ON ss.ss_hdemo_sk = hd_sales.hd_demo_sk                   -- join 2
    JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk                           -- join 3
    JOIN promotion p2
        ON ss.ss_promo_sk = p2.p_promo_sk                          -- join 4 (second alias of promotion)
    JOIN item i2
        ON p.p_item_sk = i2.i_item_sk                               -- join 5
    JOIN catalog_returns cr
        ON cr.cr_item_sk = i2.i_item_sk                             -- join 6
    JOIN household_demographics hd_refunded
        ON cr.cr_refunded_hdemo_sk = hd_refunded.hd_demo_sk        -- join 7
    JOIN household_demographics hd_returning
        ON cr.cr_returning_hdemo_sk = hd_returning.hd_demo_sk      -- join 8
    JOIN catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk          -- join 9
)
SELECT
    i_brand,
    p_promo_id,
    cp_department,
    SUM(ss_ext_sales_price) AS total_sales,
    SUM(cr_return_amount) AS total_returns,
    CASE
        WHEN SUM(ss_ext_sales_price) > (
            SELECT AVG(ss2.ss_ext_sales_price)
            FROM store_sales ss2
        )
        THEN 'Above Avg'
        ELSE 'Below Avg'
    END AS sales_category
FROM base
GROUP BY
    i_brand,
    p_promo_id,
    cp_department
ORDER BY total_sales DESC
LIMIT 100
