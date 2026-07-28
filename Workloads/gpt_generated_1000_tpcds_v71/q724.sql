WITH sales_agg AS (
    SELECT
        s.s_store_id,
        d.d_year,
        SUM(ss.ss_net_paid) AS total_store_sales,
        COUNT(DISTINCT i.i_category) AS distinct_categories_sold
    FROM store_sales ss
    JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
      AND cd.cd_marital_status = 'M'
      AND i.i_current_price > 50
    GROUP BY s.s_store_id, d.d_year
),
returns_agg AS (
    SELECT
        s.s_store_id,
        d.d_year,
        SUM(cr.cr_net_loss) AS total_returns_loss
    FROM catalog_returns cr
    JOIN catalog_sales cs
        ON cr.cr_order_number = cs.cs_order_number
    JOIN item i
        ON cr.cr_item_sk = i.i_item_sk
    JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN store s
        ON s.s_closed_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
      AND cr.cr_warehouse_sk = 1
      AND i.i_brand = 'Brand#45'
      AND cr.cr_reason_sk IN (
            SELECT DISTINCT r.r_reason_sk
            FROM reason r
            WHERE r.r_reason_desc LIKE '%damaged%'
               OR r.r_reason_desc LIKE '%defect%'
        )
    GROUP BY s.s_store_id, d.d_year
)
SELECT
    sa.s_store_id,
    AVG(sa.total_store_sales - COALESCE(ra.total_returns_loss, 0)) AS avg_net_sales,
    SUM(sa.distinct_categories_sold) AS total_distinct_categories
FROM sales_agg sa
LEFT JOIN returns_agg ra
    ON sa.s_store_id = ra.s_store_id
   AND sa.d_year = ra.d_year
GROUP BY sa.s_store_id
HAVING AVG(sa.total_store_sales - COALESCE(ra.total_returns_loss, 0)) > 15000
ORDER BY avg_net_sales DESC
LIMIT 100
