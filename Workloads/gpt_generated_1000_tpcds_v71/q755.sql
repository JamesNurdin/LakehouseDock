WITH sales_page AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_catalog_page_sk,
        cp.cp_department,
        cp.cp_catalog_page_number,
        cp.cp_catalog_page_id,
        SUM(cs.cs_net_paid_inc_ship_tax) AS total_net_paid,
        SUM(cs.cs_quantity) AS total_quantity,
        AVG(cs.cs_ext_tax) AS avg_ext_tax,
        COUNT(*) AS txn_count
    FROM catalog_sales cs
    INNER JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE
        cp.cp_department = 'Books'
        AND cs.cs_quantity > 1
        AND cs.cs_ext_tax BETWEEN 5 AND 100
        AND cs.cs_net_paid_inc_ship_tax > 5000
        AND cp.cp_start_date_sk > 2451000
        AND EXISTS (
            SELECT 1
            FROM household_demographics hd
            WHERE hd.hd_demo_sk = cs.cs_bill_hdemo_sk
              AND hd.hd_dep_count >= 2
        )
    GROUP BY
        cs.cs_sold_date_sk,
        cs.cs_catalog_page_sk,
        cp.cp_department,
        cp.cp_catalog_page_number,
        cp.cp_catalog_page_id
)
SELECT
    sp.cp_department,
    sp.cp_catalog_page_number,
    sp.cp_catalog_page_id,
    sp.total_net_paid,
    sp.total_quantity,
    sp.avg_ext_tax,
    sp.txn_count,
    RANK() OVER (ORDER BY sp.total_net_paid DESC) AS revenue_rank,
    CASE
        WHEN sp.total_quantity > 100 THEN 'HIGH_VOLUME'
        WHEN sp.total_quantity BETWEEN 50 AND 100 THEN 'MEDIUM_VOLUME'
        ELSE 'LOW_VOLUME'
    END AS volume_category
FROM sales_page sp
ORDER BY revenue_rank
LIMIT 100
