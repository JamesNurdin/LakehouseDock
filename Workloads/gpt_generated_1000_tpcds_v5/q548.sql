WITH filtered_returns AS (
    SELECT
        cr_returned_date_sk,
        cr_return_amount,
        cr_store_credit,
        cr_return_quantity,
        cr_return_ship_cost,
        cr_fee
    FROM catalog_returns
    WHERE cr_store_credit > 50
      AND cr_return_amount > 100
      AND cr_return_quantity >= 1
),
filtered_sales AS (
    SELECT
        ws_sold_date_sk,
        ws_net_paid_inc_ship,
        ws_ext_discount_amt,
        ws_net_profit,
        ws_quantity
    FROM web_sales
    WHERE ws_net_paid_inc_ship > 500
      AND ws_ext_discount_amt < 2000
)
SELECT
    d.d_year,
    d.d_month_seq,
    COUNT(DISTINCT fr.cr_returned_date_sk) AS cnt_return_dates,
    SUM(fr.cr_return_amount) AS sum_return_amount,
    SUM(fs.ws_net_paid_inc_ship) AS sum_sales_net_paid,
    AVG(fs.ws_ext_discount_amt) AS avg_discount_amt,
    MAX(fs.ws_net_profit) AS max_net_profit,
    MIN(fr.cr_return_ship_cost) AS min_return_ship_cost
FROM filtered_returns fr
JOIN date_dim d
    ON fr.cr_returned_date_sk = d.d_date_sk
JOIN filtered_sales fs
    ON fs.ws_sold_date_sk = d.d_date_sk
WHERE d.d_year = 2002
  AND d.d_month_seq BETWEEN 1200 AND 1300
  AND d.d_dow IN (2, 3)
  AND d.d_current_day = 'N'
GROUP BY ROLLUP (d.d_year, d.d_month_seq)
ORDER BY d.d_year, d.d_month_seq
LIMIT 100
