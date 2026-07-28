-- Goal: Compare yearly total profit from store sales to total loss from store returns by item category for year 2001, 
-- include the average current price of items in each category, and list the results ordered by year, category and record type.
WITH sales_agg AS (
    SELECT
        d.d_year,
        i.i_category,
        SUM(ss.ss_net_profit) AS total_profit,
        (SELECT AVG(i2.i_current_price)
         FROM item i2
         WHERE i2.i_category = i.i_category) AS avg_price
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
      AND EXISTS (
          SELECT 1
          FROM item i3
          WHERE i3.i_category = i.i_category
            AND i3.i_current_price > 100
      )
    GROUP BY d.d_year, i.i_category
),
returns_agg AS (
    SELECT
        d.d_year,
        i.i_category,
        SUM(sr.sr_net_loss) AS total_loss,
        (SELECT AVG(i2.i_current_price)
         FROM item i2
         WHERE i2.i_category = i.i_category) AS avg_price
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
      AND EXISTS (
          SELECT 1
          FROM item i3
          WHERE i3.i_category = i.i_category
            AND i3.i_current_price > 100
      )
    GROUP BY d.d_year, i.i_category
)
SELECT
    'PROFIT' AS record_type,
    s.d_year,
    s.i_category,
    s.total_profit AS amount,
    s.avg_price
FROM sales_agg s
UNION ALL
SELECT
    'LOSS' AS record_type,
    r.d_year,
    r.i_category,
    r.total_loss AS amount,
    r.avg_price
FROM returns_agg r
ORDER BY d_year DESC, i_category, record_type
LIMIT 100
