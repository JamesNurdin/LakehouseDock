WITH key_intersection AS (
    SELECT cs_order_number AS key
    FROM catalog_sales
    WHERE cs_ext_tax > 0
    INTERSECT
    SELECT ss_ticket_number AS key
    FROM store_sales
    WHERE ss_ext_tax > 0
)
SELECT
    ds_store.d_year AS store_year,
    ds_catalog.d_year AS catalog_year,
    ds_web_create.d_year AS web_creation_year,
    SUM(cs.cs_ext_sales_price) AS total_catalog_sales,
    SUM(ss.ss_ext_sales_price) AS total_store_sales,
    COUNT(DISTINCT cs.cs_bill_customer_sk) AS distinct_bill_customers,
    COUNT(DISTINCT ss.ss_store_sk) AS distinct_stores,
    SUM(CASE WHEN cs.cs_net_profit > 0 THEN 1 ELSE 0 END) AS profitable_catalog_orders,
    MAX(l.max_price) AS max_customer_sales_price,
    CASE WHEN SUM(cs.cs_ext_tax) > (SELECT avg(cs5.cs_ext_tax) FROM catalog_sales cs5) THEN 'Above Avg Tax' ELSE 'Below Avg Tax' END AS tax_category
FROM
    store_sales ss
    JOIN date_dim ds_store
        ON ss.ss_sold_date_sk = ds_store.d_date_sk
    JOIN customer_demographics cd_store
        ON ss.ss_cdemo_sk = cd_store.cd_demo_sk
    JOIN household_demographics hd_store
        ON ss.ss_hdemo_sk = hd_store.hd_demo_sk
    JOIN catalog_sales cs
        ON cs.cs_sold_date_sk = ds_store.d_date_sk
        AND cs.cs_bill_cdemo_sk = cd_store.cd_demo_sk
        AND cs.cs_bill_hdemo_sk = hd_store.hd_demo_sk
    JOIN date_dim ds_catalog
        ON cs.cs_ship_date_sk = ds_catalog.d_date_sk
    JOIN customer_demographics cd_bill
        ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
    JOIN household_demographics hd_bill
        ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN customer_demographics cd_ship
        ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
    JOIN household_demographics hd_ship
        ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
    JOIN web_page wp
        ON wp.wp_customer_sk = cs.cs_bill_customer_sk
    JOIN date_dim ds_web_create
        ON wp.wp_creation_date_sk = ds_web_create.d_date_sk
    JOIN date_dim ds_web_access
        ON wp.wp_access_date_sk = ds_web_access.d_date_sk
    CROSS JOIN LATERAL (
        SELECT max(cs2.cs_ext_sales_price) AS max_price
        FROM catalog_sales cs2
        WHERE cs2.cs_bill_customer_sk = cs.cs_bill_customer_sk
    ) l
WHERE
    cs.cs_ext_tax > (SELECT avg(cs3.cs_ext_tax) FROM catalog_sales cs3)
    AND EXISTS (
        SELECT 1
        FROM web_page wp2
        WHERE wp2.wp_customer_sk = cs.cs_bill_customer_sk
          AND wp2.wp_type = 'Home'
    )
    AND cs.cs_order_number IN (SELECT key FROM key_intersection)
GROUP BY
    ds_store.d_year,
    ds_catalog.d_year,
    ds_web_create.d_year
ORDER BY
    store_year DESC,
    total_catalog_sales DESC
LIMIT 100
