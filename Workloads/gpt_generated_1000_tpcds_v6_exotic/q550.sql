/* goal: Analyze high‑value sales by time shift, showing quantity, distinct items sold and average net paid, and rank shifts by total quantity */
WITH filtered_sales AS (
    SELECT
        cs.cs_sold_time_sk,
        cs.cs_ship_date_sk,
        cs.cs_ext_tax,
        cs.cs_net_paid,
        cs.cs_quantity,
        cs.cs_item_sk
    FROM catalog_sales cs
    WHERE cs.cs_ship_date_sk BETWEEN 2450880 AND 2450895
      AND cs.cs_ext_tax > 50
      AND cs.cs_quantity >= 2
),
agg_sales AS (
    SELECT
        td.t_shift,
        td.t_hour,
        COUNT(DISTINCT fs.cs_item_sk) AS distinct_items_sold,
        SUM(fs.cs_quantity) AS total_quantity,
        AVG(fs.cs_net_paid) AS avg_net_paid,
        MAX(fs.cs_ext_tax) AS max_ext_tax
    FROM filtered_sales fs
    LEFT JOIN time_dim td
        ON fs.cs_sold_time_sk = td.t_time_sk
    WHERE EXISTS (
        SELECT 1
        FROM time_dim td2
        WHERE td2.t_shift = td.t_shift
          AND td2.t_minute IN (9, 15, 17)
    )
    GROUP BY td.t_shift, td.t_hour
    HAVING SUM(fs.cs_quantity) > 10
)
SELECT
    a.t_shift,
    a.t_hour,
    a.distinct_items_sold,
    a.total_quantity,
    a.avg_net_paid,
    a.max_ext_tax,
    ROW_NUMBER() OVER (PARTITION BY a.t_shift ORDER BY a.total_quantity DESC) AS rn_shift
FROM agg_sales a
ORDER BY a.t_shift, a.total_quantity DESC
LIMIT 100
