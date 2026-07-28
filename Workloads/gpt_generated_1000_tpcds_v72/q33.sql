-- goal: Identify top returning items (by total return amount) for customers whose demographics and item descriptions match specific string patterns, excluding returns for items that were stocked in Alabama warehouses on the return date.
WITH returns_data AS (
    SELECT
        wr.wr_returned_date_sk,
        wr.wr_item_sk,
        wr.wr_return_quantity,
        wr.wr_return_amt,
        cd.cd_gender,
        cd.cd_marital_status,
        i.i_item_desc,
        i.i_color,
        i.i_brand,
        i.i_category,
        d.d_year,
        regexp_extract(i.i_item_desc, '(\\d+)', 1) AS numeric_code,
        CONCAT(i.i_brand, '-', i.i_category) AS brand_category
    FROM web_returns wr
    JOIN date_dim d
        ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN item i
        ON wr.wr_item_sk = i.i_item_sk
    JOIN customer_demographics cd
        ON wr.wr_returning_cdemo_sk = cd.cd_demo_sk
    WHERE regexp_like(i.i_item_desc, '^\\d{3}')
      AND i.i_color LIKE 'R%'
      AND d.d_year BETWEEN 1910 AND 1915
)
SELECT
    rd.d_year,
    rd.brand_category,
    rd.cd_gender,
    rd.numeric_code,
    COUNT(DISTINCT rd.cd_marital_status) AS distinct_marital_status_cnt,
    SUM(rd.wr_return_amt) AS total_return_amount,
    SUM(rd.wr_return_quantity) AS total_return_qty
FROM returns_data rd
WHERE NOT EXISTS (
    SELECT 1
    FROM inventory inv
    JOIN warehouse w
        ON inv.inv_warehouse_sk = w.w_warehouse_sk
    WHERE inv.inv_date_sk = rd.wr_returned_date_sk
      AND inv.inv_item_sk = rd.wr_item_sk
      AND w.w_state = 'AL'
)
GROUP BY rd.d_year, rd.brand_category, rd.cd_gender, rd.numeric_code
ORDER BY total_return_amount DESC
LIMIT 100
