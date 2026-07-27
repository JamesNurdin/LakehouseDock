WITH aggregated AS (
    SELECT
        cs.cs_item_sk,
        d.d_year,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_quantity) AS total_quantity,
        AVG(inv.inv_quantity_on_hand) AS avg_inventory,
        CASE WHEN SUM(cs.cs_net_profit) > 0 THEN 'Profit' ELSE 'Loss' END AS profit_flag
    FROM catalog_sales cs
    JOIN date_dim d
        ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN inventory inv
        ON inv.inv_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND cs.cs_quantity > 5
      AND inv.inv_quantity_on_hand > 100
      AND cs.cs_wholesale_cost > 20
    GROUP BY cs.cs_item_sk, d.d_year
)
SELECT
    a.cs_item_sk,
    a.d_year,
    a.total_sales,
    a.total_quantity,
    a.avg_inventory,
    a.profit_flag,
    RANK() OVER (PARTITION BY a.d_year ORDER BY a.total_sales DESC) AS sales_rank
FROM aggregated a
ORDER BY sales_rank
LIMIT 100
