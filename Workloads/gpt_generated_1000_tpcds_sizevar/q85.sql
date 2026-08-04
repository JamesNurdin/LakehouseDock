WITH store_sales_agg AS (
       SELECT
           s.s_store_id               AS store_id,
           i.i_item_id                AS item_id,
           i.i_item_sk                AS item_sk,
           d.d_year                   AS year,
           SUM(ss.ss_net_paid)       AS total_sales
       FROM store_sales ss
       JOIN store s
         ON ss.ss_store_sk = s.s_store_sk
       JOIN item i
         ON ss.ss_item_sk = i.i_item_sk
       JOIN date_dim d
         ON ss.ss_sold_date_sk = d.d_date_sk
       WHERE d.d_year = 2001
       GROUP BY s.s_store_id, i.i_item_id, i.i_item_sk, d.d_year
),
catalog_sales_agg AS (
       SELECT
           CAST(NULL AS varchar)      AS store_id,
           i.i_item_id                AS item_id,
           i.i_item_sk                AS item_sk,
           d.d_year                   AS year,
           SUM(cs.cs_net_paid)       AS total_sales
       FROM catalog_sales cs
       JOIN item i
         ON cs.cs_item_sk = i.i_item_sk
       JOIN date_dim d
         ON cs.cs_sold_date_sk = d.d_date_sk
       WHERE d.d_year = 2001
       GROUP BY i.i_item_id, i.i_item_sk, d.d_year
),
union_sales AS (
       SELECT * FROM store_sales_agg
       UNION ALL
       SELECT * FROM catalog_sales_agg
)
SELECT
    us.store_id,
    us.item_id,
    us.year,
    us.total_sales,
    (
        SELECT SUM(i2.inv_quantity_on_hand)
        FROM inventory i2
        JOIN date_dim d2
          ON i2.inv_date_sk = d2.d_date_sk
        WHERE i2.inv_item_sk = us.item_sk
          AND d2.d_year = us.year
    ) AS inventory_qty,
    CASE
        WHEN us.total_sales > (SELECT AVG(total_sales) FROM union_sales) THEN TRUE
        ELSE FALSE
    END AS above_avg_flag
FROM union_sales us
WHERE us.total_sales > 0
ORDER BY us.total_sales DESC
