WITH
    filtered_time AS (
        SELECT t_time_sk, t_hour, t_minute, t_am_pm
        FROM time_dim
        WHERE t_minute IN (0, 12, 17)
          AND t_am_pm = 'PM'
    ),
    store_sales_agg AS (
        SELECT
            s.s_store_id,
            s.s_store_sk,
            ft.t_hour,
            SUM(ss.ss_net_paid) AS total_net_paid,
            AVG(ss.ss_ext_discount_amt) AS avg_discount,
            COUNT(*) AS sales_rows,
            cd.cd_gender
        FROM store_sales ss
        JOIN filtered_time ft ON ss.ss_sold_time_sk = ft.t_time_sk
        JOIN store s ON ss.ss_store_sk = s.s_store_sk
        JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
        WHERE cd.cd_gender = 'F'
          AND EXISTS (
              SELECT 1
              FROM store_returns sr
              WHERE sr.sr_store_sk = s.s_store_sk
                AND sr.sr_return_quantity > 0
          )
        GROUP BY s.s_store_id, s.s_store_sk, ft.t_hour, cd.cd_gender
    )
SELECT
    ssa.s_store_id AS store_id,
    ssa.t_hour AS hour,
    ssa.total_net_paid,
    ssa.avg_discount,
    ssa.sales_rows,
    d.distinct_items,
    (
        SELECT SUM(ss3.ss_net_paid)
        FROM store_sales ss3
        WHERE ss3.ss_store_sk = ssa.s_store_sk
    ) AS overall_net_paid,
    'store_sales' AS source
FROM store_sales_agg ssa
CROSS JOIN LATERAL (
    SELECT COUNT(DISTINCT ss2.ss_item_sk) AS distinct_items
    FROM store_sales ss2
    JOIN filtered_time ft2 ON ss2.ss_sold_time_sk = ft2.t_time_sk
    WHERE ss2.ss_store_sk = ssa.s_store_sk
      AND ft2.t_hour = ssa.t_hour
) AS d

UNION ALL

SELECT
    CAST(NULL AS varchar) AS store_id,
    ft.t_hour AS hour,
    SUM(cs.cs_net_paid) AS total_net_paid,
    AVG(cs.cs_ext_discount_amt) AS avg_discount,
    COUNT(*) AS sales_rows,
    COUNT(DISTINCT cs.cs_item_sk) AS distinct_items,
    (
        SELECT SUM(cs2.cs_net_paid)
        FROM catalog_sales cs2
    ) AS overall_net_paid,
    'catalog_sales' AS source
FROM catalog_sales cs
JOIN filtered_time ft ON cs.cs_sold_time_sk = ft.t_time_sk
JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
WHERE cd.cd_gender = 'M'
GROUP BY ft.t_hour
ORDER BY store_id, hour
LIMIT 100
