WITH sales_agg AS (
    SELECT
        i.i_class AS item_class,
        d.d_year AS year,
        SUM(cs.cs_net_paid) AS sales_amount,
        COUNT(*) AS sales_cnt
    FROM tpcds.catalog_sales cs
    JOIN tpcds.item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN tpcds.date_dim d
        ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_date BETWEEN DATE '2001-01-01' AND DATE '2002-12-31'
      AND i.i_class = 'shirts'
      AND i.i_manufact_id IN (
          SELECT i2.i_manufact_id
          FROM tpcds.item i2
          WHERE i2.i_category = 'fragrances'
      )
      AND EXISTS (
          SELECT 1
          FROM tpcds.catalog_page cp
          WHERE cp.cp_catalog_page_sk = cs.cs_catalog_page_sk
            AND cp.cp_type = 'promotion'
      )
    GROUP BY i.i_class, d.d_year
),
returns_agg AS (
    SELECT
        i.i_class AS item_class,
        d.d_year AS year,
        SUM(wr.wr_net_loss) AS returns_amount,
        COUNT(*) AS returns_cnt
    FROM tpcds.web_returns wr
    JOIN tpcds.item i
        ON wr.wr_item_sk = i.i_item_sk
    JOIN tpcds.date_dim d
        ON wr.wr_returned_date_sk = d.d_date_sk
    WHERE d.d_date BETWEEN DATE '2001-01-01' AND DATE '2002-12-31'
      AND i.i_class = 'shirts'
      AND i.i_manufact_id IN (
          SELECT i2.i_manufact_id
          FROM tpcds.item i2
          WHERE i2.i_category = 'fragrances'
      )
    GROUP BY i.i_class, d.d_year
)
SELECT
    item_class,
    year,
    sales_amount,
    sales_cnt,
    NULL AS returns_amount,
    NULL AS returns_cnt,
    'sales' AS source
FROM sales_agg

UNION ALL

SELECT
    item_class,
    year,
    NULL AS sales_amount,
    NULL AS sales_cnt,
    returns_amount,
    returns_cnt,
    'returns' AS source
FROM returns_agg

ORDER BY item_class, year, source
LIMIT 100
