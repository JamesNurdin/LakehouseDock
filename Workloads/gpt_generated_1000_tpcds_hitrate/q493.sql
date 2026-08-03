WITH sales_agg AS (
    SELECT
        s.s_store_id AS store_id,
        td.t_hour,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit,
        CASE
            WHEN SUM(ss.ss_net_profit) > 100000 THEN 'HIGH'
            WHEN SUM(ss.ss_net_profit) > 50000 THEN 'MEDIUM'
            ELSE 'LOW'
        END AS profit_category
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    WHERE ss.ss_sold_date_sk BETWEEN 2451545 AND 2451910
      AND EXISTS (
          SELECT 1
          FROM catalog_returns cr
          WHERE cr.cr_refunded_customer_sk = c.c_customer_sk
            AND cr.cr_returned_date_sk = ss.ss_sold_date_sk
      )
    GROUP BY GROUPING SETS (
        (s.s_store_id, td.t_hour),
        (s.s_store_id)
    )
    HAVING SUM(ss.ss_ext_sales_price) > 10000
),
returns_agg AS (
    SELECT
        cc.cc_call_center_id AS call_center_id,
        r.r_reason_desc,
        SUM(cr.cr_return_amount) AS total_return_amount,
        CASE WHEN SUM(cr.cr_return_amount) > 5000 THEN 'Significant' ELSE 'Minor' END AS return_severity,
        CAST(NULL AS integer) AS hour
    FROM catalog_returns cr
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN time_dim td ON cr.cr_returned_time_sk = td.t_time_sk
    WHERE td.t_hour BETWEEN 8 AND 18
      AND EXISTS (
          SELECT 1
          FROM catalog_sales cs
          WHERE cs.cs_order_number = cr.cr_order_number
            AND cs.cs_sold_date_sk = cr.cr_returned_date_sk
      )
    GROUP BY GROUPING SETS (
        (cc.cc_call_center_id, r.r_reason_desc),
        (cc.cc_call_center_id)
    )
    HAVING SUM(cr.cr_return_amount) > 2000
)
SELECT
    sa.store_id AS entity_id,
    CAST('Store Sales' AS varchar) AS description,
    sa.total_sales AS metric_value,
    sa.profit_category AS category,
    sa.t_hour AS hour
FROM sales_agg sa
WHERE sa.t_hour IS NOT NULL
UNION ALL
SELECT
    ra.call_center_id AS entity_id,
    ra.r_reason_desc AS description,
    ra.total_return_amount AS metric_value,
    ra.return_severity AS category,
    ra.hour AS hour
FROM returns_agg ra
ORDER BY metric_value DESC
LIMIT 100
