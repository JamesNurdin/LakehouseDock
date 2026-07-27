WITH sales_agg AS (
    SELECT
        d.d_date AS event_date,
        cp.cp_catalog_page_id AS entity,
        SUM(cs.cs_ext_sales_price) AS metric,
        CASE WHEN SUM(cs.cs_ext_discount_amt) > 50 THEN 'High Discount' ELSE 'Low Discount' END AS category,
        ROW_NUMBER() OVER (PARTITION BY cp.cp_catalog_page_id ORDER BY d.d_date) AS rn,
        SUM(SUM(cs.cs_ext_sales_price)) OVER (
            PARTITION BY cp.cp_catalog_page_id
            ORDER BY d.d_date
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS cum_metric
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    WHERE d.d_year = 2001
    GROUP BY d.d_date, cp.cp_catalog_page_id
),
returns_agg AS (
    SELECT
        d.d_date AS event_date,
        s.s_store_id AS entity,
        SUM(sr.sr_return_amt) AS metric,
        CASE WHEN SUM(sr.sr_return_amt) > 2000 THEN 'Large Return' ELSE 'Small Return' END AS category,
        ROW_NUMBER() OVER (PARTITION BY s.s_store_id ORDER BY d.d_date DESC) AS rn,
        SUM(SUM(sr.sr_return_amt)) OVER (
            PARTITION BY s.s_store_id
            ORDER BY d.d_date
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS cum_metric
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    WHERE d.d_year = 2001
    GROUP BY d.d_date, s.s_store_id
)
SELECT event_date, entity, metric, category, rn, cum_metric
FROM sales_agg
UNION ALL
SELECT event_date, entity, metric, category, rn, cum_metric
FROM returns_agg
ORDER BY event_date DESC, metric DESC
LIMIT 100
