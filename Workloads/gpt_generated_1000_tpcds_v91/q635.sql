WITH intersect_items AS (
    SELECT i_item_sk
    FROM item
    WHERE regexp_like(i_item_desc, '\\d{3}')
    INTERSECT
    SELECT i_item_sk
    FROM item
    WHERE i_item_desc LIKE '%blue%'
),

sales_agg AS (
    SELECT
        cs.cs_ship_mode_sk,
        SUM(cs.cs_net_paid) AS total_net_paid,
        COUNT(*) AS sales_cnt,
        COUNT(DISTINCT cs.cs_bill_customer_sk) AS distinct_customers
    FROM catalog_sales cs
    INNER JOIN intersect_items ii
        ON cs.cs_item_sk = ii.i_item_sk
    WHERE NOT EXISTS (
        SELECT 1
        FROM web_returns wr
        WHERE wr.wr_item_sk = cs.cs_item_sk
    )
    GROUP BY cs.cs_ship_mode_sk
)

SELECT
    COALESCE(sm.sm_ship_mode_id, 'UNKNOWN') AS ship_mode_id,
    COALESCE(sm.sm_type, 'NO_SHIP') AS ship_type,
    COALESCE(sm.sm_carrier, 'NONE') AS carrier,
    SUBSTRING(sm.sm_carrier FROM 1 FOR 3) AS carrier_prefix,
    CASE WHEN sm.sm_type = 'AIR' THEN 'Air' ELSE 'Other' END AS ship_mode_category,
    COALESCE(sa.total_net_paid, CAST(0 AS decimal(7,2))) AS total_net_paid,
    COALESCE(sa.sales_cnt, 0) AS sales_cnt,
    COALESCE(sa.distinct_customers, 0) AS distinct_customers,
    (SELECT avg(cs3.cs_net_paid) FROM catalog_sales cs3) AS avg_net_paid_all,
    CONCAT('ShipMode: ', COALESCE(sm.sm_ship_mode_id, 'N/A'), ' (', COALESCE(sm.sm_type, 'N/A'), ')') AS ship_mode_label
FROM ship_mode sm
FULL OUTER JOIN sales_agg sa
    ON sm.sm_ship_mode_sk = sa.cs_ship_mode_sk
ORDER BY total_net_paid DESC, ship_mode_category
