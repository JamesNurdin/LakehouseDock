WITH sales AS (
    SELECT
        d.d_year AS year,
        i.i_brand AS brand,
        'sales' AS src,
        SUM(cs.cs_net_paid) AS total_amount,
        attr
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    CROSS JOIN UNNEST(ARRAY[i.i_color, i.i_size]) AS t(attr)
    WHERE cs.cs_item_sk IN (
        SELECT i2.i_item_sk
        FROM item i2
        WHERE i2.i_category = 'Electronics'
    )
    GROUP BY d.d_year, i.i_brand, attr
),
returns AS (
    SELECT
        d.d_year AS year,
        i.i_brand AS brand,
        'returns' AS src,
        SUM(cr.cr_return_amount) AS total_amount,
        attr
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    CROSS JOIN UNNEST(ARRAY[i.i_color, i.i_size]) AS t(attr)
    WHERE cr.cr_item_sk IN (
        SELECT i2.i_item_sk
        FROM item i2
        WHERE i2.i_category = 'Electronics'
    )
    GROUP BY d.d_year, i.i_brand, attr
)
SELECT year,
       brand,
       src,
       total_amount,
       attr
FROM sales
UNION
SELECT year,
       brand,
       src,
       total_amount,
       attr
FROM returns
ORDER BY year DESC,
         total_amount DESC
LIMIT 100
