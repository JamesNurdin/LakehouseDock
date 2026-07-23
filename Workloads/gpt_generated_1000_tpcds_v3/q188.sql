WITH sales_agg AS (
    SELECT s.s_store_id AS store_id,
           'sales' AS metric_type,
           SUM(ss.ss_net_profit) AS total_amount
    FROM store_sales ss
    JOIN store s
      ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d
      ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY s.s_store_id
    HAVING SUM(ss.ss_net_profit) > (
        SELECT AVG(ss2.ss_net_profit)
        FROM store_sales ss2
        JOIN date_dim d2
          ON ss2.ss_sold_date_sk = d2.d_date_sk
        WHERE d2.d_year = 2001
    )
),
returns_agg AS (
    SELECT s.s_store_id AS store_id,
           'returns' AS metric_type,
           SUM(cr.cr_net_loss) AS total_amount
    FROM catalog_returns cr
    JOIN date_dim d
      ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN store s
      ON s.s_closed_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY s.s_store_id
    HAVING SUM(cr.cr_net_loss) > (
        SELECT AVG(cr2.cr_net_loss)
        FROM catalog_returns cr2
        JOIN date_dim d2
          ON cr2.cr_returned_date_sk = d2.d_date_sk
        WHERE d2.d_year = 2001
    )
)
SELECT store_id,
       metric_type,
       total_amount
FROM (
    SELECT store_id, metric_type, total_amount FROM sales_agg
    UNION ALL
    SELECT store_id, metric_type, total_amount FROM returns_agg
) combined
ORDER BY total_amount DESC
LIMIT 100
