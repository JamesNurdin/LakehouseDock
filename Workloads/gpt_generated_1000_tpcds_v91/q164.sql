WITH brand_colors AS (
    SELECT i_brand,
           ARRAY_AGG(DISTINCT i_color) AS colors
    FROM item
    GROUP BY i_brand
),
year_returns AS (
    SELECT
        d.d_date AS return_date,
        i.i_brand AS brand,
        ccolor AS color,
        SUM(wr.wr_return_amt) AS total_return_amount,
        SUM(wr.wr_return_quantity) AS total_quantity,
        CASE WHEN SUM(wr.wr_return_amt) > 1000 THEN 'High' ELSE 'Low' END AS amount_category,
        (SELECT MAX(d2.d_date) FROM date_dim d2) AS max_date
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    JOIN brand_colors bc ON i.i_brand = bc.i_brand
    CROSS JOIN UNNEST(bc.colors) AS t(ccolor)
    JOIN customer c ON wr.wr_refunded_customer_sk = c.c_customer_sk
    WHERE d.d_year = 2000
      AND EXISTS (
          SELECT 1
          FROM web_page wp
          WHERE wp.wp_customer_sk = c.c_customer_sk
            AND wp.wp_type = 'product'
      )
    GROUP BY d.d_date, i.i_brand, ccolor
    HAVING SUM(wr.wr_return_amt) > 0

    UNION ALL

    SELECT
        d.d_date AS return_date,
        i.i_brand AS brand,
        ccolor AS color,
        SUM(wr.wr_return_amt) AS total_return_amount,
        SUM(wr.wr_return_quantity) AS total_quantity,
        CASE WHEN SUM(wr.wr_return_amt) > 1000 THEN 'High' ELSE 'Low' END AS amount_category,
        (SELECT MAX(d2.d_date) FROM date_dim d2) AS max_date
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    JOIN brand_colors bc ON i.i_brand = bc.i_brand
    CROSS JOIN UNNEST(bc.colors) AS t(ccolor)
    JOIN customer c ON wr.wr_refunded_customer_sk = c.c_customer_sk
    WHERE d.d_year = 2001
      AND EXISTS (
          SELECT 1
          FROM web_page wp
          WHERE wp.wp_customer_sk = c.c_customer_sk
            AND wp.wp_type = 'product'
      )
    GROUP BY d.d_date, i.i_brand, ccolor
    HAVING SUM(wr.wr_return_amt) > 0
)
SELECT
    return_date,
    brand,
    color,
    total_return_amount,
    total_quantity,
    amount_category,
    ROW_NUMBER() OVER (PARTITION BY brand ORDER BY total_return_amount DESC) AS brand_rank,
    max_date
FROM year_returns
ORDER BY total_return_amount DESC, return_date DESC
LIMIT 100
