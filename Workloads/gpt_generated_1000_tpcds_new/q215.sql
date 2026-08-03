WITH
    store_sales_filtered AS (
        SELECT
            d.d_date AS sale_date,
            ss.ss_net_paid AS net_amount,
            p.p_promo_name AS promo_name
        FROM store_sales ss
        JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
        JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
        WHERE d.d_year = 2002
          AND ss.ss_net_paid > (SELECT MAX(ss2.ss_net_paid) FROM store_sales ss2)
    ),
    catalog_returns_filtered AS (
        SELECT
            d.d_date AS sale_date,
            cr.cr_return_amount AS net_amount,
            cp.cp_type AS promo_name
        FROM catalog_returns cr
        JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
        JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
        JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
        WHERE d.d_year = 2002
          AND w.w_state = 'CA'
          AND cr.cr_return_amount > (SELECT MIN(cr2.cr_return_amount) FROM catalog_returns cr2)
    )
SELECT sale_date,
       net_amount,
       promo_name
FROM store_sales_filtered
UNION ALL
SELECT sale_date,
       net_amount,
       promo_name
FROM catalog_returns_filtered
ORDER BY sale_date DESC, net_amount DESC
LIMIT 100
