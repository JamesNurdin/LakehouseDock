WITH ss_sample AS (
    SELECT *
    FROM store_sales TABLESAMPLE BERNOULLI (10)
)
SELECT
    promotion.p_promo_name,
    call_center.cc_name,
    date_dim.d_year,
    SUM(ss_sample.ss_net_paid_inc_tax) AS total_net_paid,
    COUNT(DISTINCT catalog_sales.cs_order_number) AS distinct_orders,
    AVG(catalog_sales.cs_ext_discount_amt) AS avg_discount,
    MIN(catalog_sales.cs_ext_sales_price) AS min_sales_price,
    MAX(catalog_sales.cs_ext_sales_price) AS max_sales_price
FROM ss_sample
JOIN date_dim
    ON ss_sample.ss_sold_date_sk = date_dim.d_date_sk
JOIN promotion
    ON ss_sample.ss_promo_sk = promotion.p_promo_sk
JOIN catalog_sales
    ON catalog_sales.cs_promo_sk = promotion.p_promo_sk
JOIN call_center
    ON catalog_sales.cs_call_center_sk = call_center.cc_call_center_sk
JOIN warehouse
    ON catalog_sales.cs_warehouse_sk = warehouse.w_warehouse_sk
JOIN catalog_returns
    ON catalog_returns.cr_order_number = catalog_sales.cs_order_number
   AND catalog_returns.cr_item_sk = catalog_sales.cs_item_sk
WHERE
    date_dim.d_year = 2001
    AND promotion.p_channel_dmail = 'Y'
    AND ss_sample.ss_ext_wholesale_cost > 1000
    AND call_center.cc_state = 'CA'
    AND ss_sample.ss_net_paid_inc_tax > (
        SELECT AVG(ss_net_paid_inc_tax)
        FROM store_sales
        WHERE ss_sold_date_sk = 2451234
    )
    AND catalog_sales.cs_item_sk IN (
        SELECT cr_item_sk
        FROM catalog_returns
        WHERE cr_return_quantity > 0
    )
GROUP BY
    promotion.p_promo_name,
    call_center.cc_name,
    date_dim.d_year
LIMIT 100
