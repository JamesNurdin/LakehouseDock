WITH catalog_sales_sample AS (
    SELECT *
    FROM catalog_sales TABLESAMPLE BERNOULLI (10)
),
sales_agg AS (
    SELECT
        i.i_class AS item_class,
        'sales_amount' AS metric_name,
        SUM(cs.cs_net_paid_inc_ship_tax) AS metric_amount,
        COUNT(*) AS metric_count,
        SUBSTRING(i.i_item_desc FROM 1 FOR 10) AS extracted_desc
    FROM catalog_sales_sample cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    WHERE REGEXP_LIKE(i.i_class, 'apparel|fragrances')
      AND EXISTS (
          SELECT 1
          FROM household_demographics hd
          JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
          WHERE hd.hd_demo_sk = cs.cs_bill_hdemo_sk
            AND ib.ib_lower_bound >= 60000
      )
    GROUP BY i.i_class, SUBSTRING(i.i_item_desc FROM 1 FOR 10)
),
returns_agg AS (
    SELECT
        i.i_class AS item_class,
        'return_amount' AS metric_name,
        SUM(cr.cr_return_amount) AS metric_amount,
        COUNT(*) AS metric_count,
        REGEXP_EXTRACT(i.i_item_desc, '^(\\w+)', 1) AS extracted_desc
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    WHERE REGEXP_LIKE(i.i_item_desc, '.*(scanners|shirts).*')
    GROUP BY i.i_class, REGEXP_EXTRACT(i.i_item_desc, '^(\\w+)', 1)
),
union_metrics AS (
    SELECT item_class, metric_name, metric_amount, metric_count, extracted_desc
    FROM sales_agg
    UNION DISTINCT
    SELECT item_class, metric_name, metric_amount, metric_count, extracted_desc
    FROM returns_agg
),
store_agg AS (
    SELECT
        i.i_class AS item_class,
        SUM(ss.ss_net_paid_inc_tax) AS store_sales_total
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    GROUP BY i.i_class
)
SELECT
    COALESCE(u.item_class, s.item_class) AS item_class,
    u.metric_name,
    u.metric_amount,
    u.metric_count,
    u.extracted_desc,
    s.store_sales_total
FROM union_metrics u
FULL OUTER JOIN store_agg s
    ON u.item_class = s.item_class
ORDER BY u.metric_amount DESC NULLS LAST
LIMIT 100
