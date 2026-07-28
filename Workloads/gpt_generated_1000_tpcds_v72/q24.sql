WITH aggregated_sales AS (
    SELECT
        d.d_year,
        i.i_item_sk,
        i.i_product_name,
        SUM(ss.ss_quantity) AS total_qty,
        SUM(ss.ss_net_paid) AS total_net,
        RANK() OVER (PARTITION BY d.d_year ORDER BY SUM(ss.ss_net_paid) DESC) AS sales_rank,
        'store' AS channel
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 2001 AND 2002
    GROUP BY d.d_year, i.i_item_sk, i.i_product_name

    UNION ALL

    SELECT
        d.d_year,
        i.i_item_sk,
        i.i_product_name,
        SUM(cs.cs_quantity) AS total_qty,
        SUM(cs.cs_net_paid) AS total_net,
        RANK() OVER (PARTITION BY d.d_year ORDER BY SUM(cs.cs_net_paid) DESC) AS sales_rank,
        'catalog' AS channel
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 2001 AND 2002
    GROUP BY d.d_year, i.i_item_sk, i.i_product_name
)
SELECT
    asales.d_year,
    asales.i_item_sk,
    asales.i_product_name,
    asales.channel,
    asales.total_qty,
    asales.total_net,
    asales.sales_rank,
    CASE WHEN asales.total_net > avg_net.avg_total_net THEN 'Above Avg' ELSE 'Below Avg' END AS performance
FROM aggregated_sales asales
CROSS JOIN (
    SELECT AVG(total_net) AS avg_total_net
    FROM aggregated_sales
) avg_net
WHERE EXISTS (
    SELECT 1
    FROM inventory inv
    JOIN date_dim d2 ON inv.inv_date_sk = d2.d_date_sk
    WHERE inv.inv_item_sk = asales.i_item_sk
      AND d2.d_year = asales.d_year
      AND inv.inv_quantity_on_hand > 0
)
ORDER BY asales.d_year DESC, asales.total_net DESC
LIMIT 100
