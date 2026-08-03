WITH store_data AS (
    SELECT
        i.i_category,
        d.d_year,
        SUM(sr.sr_return_amt_inc_tax) AS store_return_total
    FROM store_returns sr
    JOIN date_dim d
        ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN item i
        ON sr.sr_item_sk = i.i_item_sk
    JOIN household_demographics hd
        ON sr.sr_hdemo_sk = hd.hd_demo_sk
    WHERE regexp_like(i.i_product_name, '[A-Z]{3}')
      AND hd.hd_buy_potential LIKE '%-%'
      AND EXISTS (
          SELECT 1
          FROM inventory inv
          WHERE inv.inv_date_sk = d.d_date_sk
            AND inv.inv_item_sk = i.i_item_sk
            AND inv.inv_quantity_on_hand > 0
      )
    GROUP BY i.i_category, d.d_year
),
web_data AS (
    SELECT
        i.i_category,
        d.d_year,
        SUM(wr.wr_return_amt_inc_tax) AS web_return_total
    FROM web_returns wr
    JOIN date_dim d
        ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN item i
        ON wr.wr_item_sk = i.i_item_sk
    JOIN household_demographics hd
        ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    WHERE regexp_like(i.i_product_name, '[0-9]{2,}')
      AND hd.hd_buy_potential LIKE '0-%'
      AND EXISTS (
          SELECT 1
          FROM inventory inv
          WHERE inv.inv_date_sk = d.d_date_sk
            AND inv.inv_item_sk = i.i_item_sk
            AND inv.inv_quantity_on_hand > 10
      )
    GROUP BY i.i_category, d.d_year
),
union_data AS (
    SELECT i_category, d_year, store_return_total AS total_return
    FROM store_data
    UNION
    SELECT i_category, d_year, web_return_total AS total_return
    FROM web_data
)
SELECT
    i_category,
    d_year,
    SUM(total_return) AS total_return_amount,
    COUNT(*) AS source_rows,
    CONCAT('Category ', i_category) AS category_label,
    SUBSTRING(i_category FROM 1 FOR 5) AS category_prefix
FROM union_data
GROUP BY
    i_category,
    d_year,
    CONCAT('Category ', i_category),
    SUBSTRING(i_category FROM 1 FOR 5)
ORDER BY total_return_amount DESC
LIMIT 100
