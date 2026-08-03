WITH
    sales_agg AS (
        SELECT
            cs_order_number,
            cs_catalog_page_sk,
            cs_warehouse_sk,
            cs_promo_sk,
            SUM(cs_ext_sales_price) AS sales_amount,
            SUM(cs_net_profit) AS profit
        FROM catalog_sales
        WHERE cs_sold_date_sk BETWEEN 2451000 AND 2452000
          AND cs_quantity > 0
          AND cs_ext_sales_price > 0
        GROUP BY cs_order_number, cs_catalog_page_sk, cs_warehouse_sk, cs_promo_sk
    ),
    returns_agg AS (
        SELECT
            cr_order_number,
            SUM(cr_return_amount) AS return_amount
        FROM catalog_returns
        WHERE cr_return_quantity > 0
          AND cr_return_amount > 0
        GROUP BY cr_order_number
    ),
    order_without_returns AS (
        SELECT cs_order_number FROM sales_agg
        EXCEPT
        SELECT cr_order_number FROM returns_agg
    ),
    promo_disc_levels AS (
        SELECT 0 AS discount_pct
        UNION ALL SELECT 10
        UNION ALL SELECT 20
    )
SELECT
    cp.cp_catalog_page_number,
    w.w_warehouse_name,
    p.p_promo_id,
    CASE
        WHEN p.p_discount_active = 'Y' THEN 'Active'
        ELSE 'Inactive'
    END AS promo_status,
    d.discount_pct,
    SUM(sa.sales_amount) AS total_sales,
    SUM(sa.profit) AS total_profit,
    COALESCE(SUM(ra.return_amount), 0) AS total_returns,
    (SUM(sa.sales_amount) - COALESCE(SUM(ra.return_amount), 0)) AS net_sales
FROM order_without_returns ow
JOIN sales_agg sa ON ow.cs_order_number = sa.cs_order_number
LEFT JOIN returns_agg ra ON sa.cs_order_number = ra.cr_order_number
JOIN catalog_page cp ON sa.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN warehouse w ON sa.cs_warehouse_sk = w.w_warehouse_sk
JOIN promotion p ON sa.cs_promo_sk = p.p_promo_sk
JOIN store_sales ss ON ss.ss_promo_sk = p.p_promo_sk
CROSS JOIN promo_disc_levels d
WHERE p.p_promo_id IN ('AAAAAAAAPAAAAAAA', 'AAAAAAAANAAAAAAA')
  AND cp.cp_catalog_number > 3
  AND w.w_state = 'TX'
  AND ss.ss_ext_tax > 10
  AND d.discount_pct = 10
GROUP BY
    cp.cp_catalog_page_number,
    w.w_warehouse_name,
    p.p_promo_id,
    CASE
        WHEN p.p_discount_active = 'Y' THEN 'Active'
        ELSE 'Inactive'
    END,
    d.discount_pct
ORDER BY net_sales DESC
OFFSET 20 ROWS FETCH NEXT 100 ROWS ONLY
