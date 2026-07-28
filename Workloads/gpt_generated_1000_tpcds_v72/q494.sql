WITH filtered_returns AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_return_amount,
        cr.cr_order_number,
        cr.cr_item_sk,
        cr.cr_return_quantity,
        cr.cr_refunded_cash
    FROM catalog_returns cr
    WHERE cr.cr_return_amount > 100
      AND cr.cr_item_sk IN (
          SELECT inv.inv_item_sk
          FROM inventory inv
          WHERE inv.inv_quantity_on_hand > 500
      )
)
SELECT
    d.d_year,
    d.d_month_seq,
    SUM(fr.cr_return_amount) AS total_return_amount,
    COUNT(DISTINCT fr.cr_order_number) AS distinct_orders,
    regexp_extract(d.d_holiday, '(.*) Day', 1) AS holiday_name,
    concat(d.d_day_name, ' ', cast(d.d_date AS varchar)) AS day_label
FROM filtered_returns fr
JOIN date_dim d
  ON fr.cr_returned_date_sk = d.d_date_sk
WHERE regexp_like(d.d_holiday, '(Christmas|New Year)')
  AND d.d_day_name LIKE '%day'
GROUP BY
    d.d_year,
    d.d_month_seq,
    regexp_extract(d.d_holiday, '(.*) Day', 1),
    concat(d.d_day_name, ' ', cast(d.d_date AS varchar))
ORDER BY total_return_amount DESC
LIMIT 100
