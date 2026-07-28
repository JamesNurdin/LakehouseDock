WITH store_ret AS (
    SELECT
        d.d_year AS year,
        'store' AS channel,
        SUM(sr.sr_net_loss) AS total_loss,
        COUNT(*) AS return_cnt,
        CASE WHEN SUM(sr.sr_return_quantity) > 100 THEN 'HighVolume' ELSE 'LowVolume' END AS volume_category
    FROM store_returns sr
    JOIN date_dim d
        ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    JOIN customer_demographics cd
        ON sr.sr_cdemo_sk = cd.cd_demo_sk
    WHERE s.s_state = 'CA'
      AND d.d_year BETWEEN 2000 AND 2002
      AND EXISTS (
          SELECT 1
          FROM warehouse w
          WHERE w.w_city = 'Liberty' AND w.w_state = s.s_state
      )
    GROUP BY d.d_year
),
catalog_ret AS (
    SELECT
        d.d_year AS year,
        'catalog' AS channel,
        SUM(cr.cr_net_loss) AS total_loss,
        COUNT(*) AS return_cnt,
        CASE WHEN AVG(cr.cr_return_quantity) > 5 THEN 'HighAvgQty' ELSE 'LowAvgQty' END AS volume_category
    FROM catalog_returns cr
    JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN customer_demographics cd
        ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    WHERE w.w_country = 'United States'
      AND d.d_year BETWEEN 2000 AND 2002
      AND cd.cd_purchase_estimate > (
          SELECT AVG(cd2.cd_purchase_estimate)
          FROM customer_demographics cd2
          WHERE cd2.cd_gender = 'M'
      )
    GROUP BY d.d_year
)
SELECT *
FROM (
    SELECT * FROM store_ret
    UNION ALL
    SELECT * FROM catalog_ret
) AS combined
ORDER BY year, channel
LIMIT 100
