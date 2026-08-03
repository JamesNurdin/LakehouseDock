WITH store_agg AS (
    SELECT d.d_date AS sales_date,
           SUM(ss.ss_net_paid) AS store_net_paid
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY d.d_date
),
catalog_agg AS (
    SELECT d.d_date AS sales_date,
           SUM(cs.cs_net_paid) AS catalog_net_paid
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY d.d_date
),
full_sales AS (
    SELECT COALESCE(sa.sales_date, ca.sales_date) AS sales_date,
           sa.store_net_paid,
           ca.catalog_net_paid
    FROM store_agg sa
    FULL OUTER JOIN catalog_agg ca ON sa.sales_date = ca.sales_date
),
sample_inventory AS (
    SELECT inv.inv_date_sk,
           inv.inv_quantity_on_hand
    FROM inventory inv TABLESAMPLE BERNOULLI (10)
),
scalar_max_quantity AS (
    SELECT MAX(cs_quantity) AS max_qty FROM catalog_sales
),
sub1 AS (
    SELECT f.sales_date,
           f.store_net_paid AS net_paid,
           'store' AS sales_source
    FROM full_sales f
    WHERE f.store_net_paid > (SELECT max_qty FROM scalar_max_quantity)
),
sub2 AS (
    SELECT d.d_date AS sales_date,
           SUM(si.ss_net_paid) AS net_paid,
           'store_sampled' AS sales_source
    FROM store_sales si
    JOIN date_dim d ON si.ss_sold_date_sk = d.d_date_sk
    JOIN sample_inventory inv ON d.d_date_sk = inv.inv_date_sk
    WHERE d.d_year = 2001
    GROUP BY d.d_date
)
SELECT sales_date,
       net_paid,
       sales_source
FROM (
    SELECT sales_date, net_paid, sales_source FROM sub1
    UNION ALL
    SELECT sales_date, net_paid, sales_source FROM sub2
) AS combined
ORDER BY net_paid DESC
LIMIT 100
