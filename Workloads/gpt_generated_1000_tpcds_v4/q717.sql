WITH promo_avg AS (
    SELECT p.p_promo_sk,
           AVG(p.p_cost) AS avg_cost
    FROM promotion p
    GROUP BY p.p_promo_sk
)
SELECT *
FROM (
    SELECT
        w.w_warehouse_id AS location_id,
        w.w_state AS state,
        d.d_year AS year,
        SUM(cs.cs_ext_sales_price) AS metric_amount,
        'sales' AS metric_type,
        pa.avg_cost AS avg_promo_cost
    FROM catalog_sales cs
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    LEFT JOIN promo_avg pa ON cs.cs_promo_sk = pa.p_promo_sk
    WHERE d.d_year = 2001
    GROUP BY w.w_warehouse_id, w.w_state, d.d_year, pa.avg_cost

    UNION ALL

    SELECT
        NULL AS location_id,
        NULL AS state,
        d.d_year AS year,
        SUM(sr.sr_net_loss) AS metric_amount,
        'return_loss' AS metric_type,
        NULL AS avg_promo_cost
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE d.d_year = 2001
      AND EXISTS (
          SELECT 1
          FROM reason r2
          WHERE r2.r_reason_sk = sr.sr_reason_sk
            AND r2.r_reason_desc LIKE '%damaged%'
      )
    GROUP BY d.d_year
) combined
ORDER BY year, metric_type, location_id
LIMIT 100
