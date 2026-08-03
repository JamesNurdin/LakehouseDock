WITH sales AS (
    SELECT
        w.w_warehouse_id,
        cp.cp_department,
        SUM(cs.cs_net_paid) AS total_net_paid,
        CASE WHEN SUM(cs.cs_net_paid) > 100000 THEN 'HIGH' ELSE 'LOW' END AS revenue_category,
        COUNT(*) AS sales_cnt
    FROM catalog_sales cs
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    GROUP BY GROUPING SETS (
        (w.w_warehouse_id),
        (cp.cp_department)
    )
),
returns AS (
    SELECT
        s.s_store_id,
        ib.ib_lower_bound,
        SUM(sr.sr_net_loss) AS total_net_loss,
        CASE WHEN SUM(sr.sr_net_loss) > 50000 THEN 'HIGH' ELSE 'LOW' END AS loss_category,
        COUNT(*) AS returns_cnt
    FROM store_returns sr
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY GROUPING SETS (
        (s.s_store_id),
        (ib.ib_lower_bound)
    )
)
SELECT
    s.w_warehouse_id    AS dim_id,
    'WAREHOUSE'          AS dim_type,
    s.total_net_paid    AS total_amount,
    s.revenue_category  AS category,
    s.sales_cnt         AS cnt
FROM sales s
WHERE s.total_net_paid > (
    SELECT AVG(total_net_paid) FROM sales
)

UNION ALL

SELECT
    r.s_store_id        AS dim_id,
    'STORE'              AS dim_type,
    r.total_net_loss    AS total_amount,
    r.loss_category     AS category,
    r.returns_cnt       AS cnt
FROM returns r
WHERE r.total_net_loss > (
    SELECT AVG(total_net_loss) FROM returns
)
  AND EXISTS (
    SELECT 1 FROM store s2
    WHERE s2.s_manager = 'John Mccoy'
      AND s2.s_store_id = r.s_store_id
  )

ORDER BY total_amount DESC
LIMIT 100
