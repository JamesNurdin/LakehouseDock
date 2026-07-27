WITH filtered_returns AS (
    SELECT
        cr_returned_date_sk,
        cr_order_number,
        cr_return_amount,
        cr_net_loss,
        cr_return_quantity
    FROM catalog_returns
    WHERE cr_return_amount > 100
      AND regexp_like(CAST(cr_return_quantity AS VARCHAR), '^1[0-9]$')
)
SELECT
    d.d_year,
    d.d_quarter_name,
    CONCAT(d.d_day_name, ' ', d.d_holiday) AS day_holiday_label,
    COUNT(DISTINCT cr.cr_order_number) AS distinct_orders,
    SUM(cr.cr_return_amount) AS total_return_amount,
    AVG(cr.cr_net_loss) AS avg_net_loss,
    regexp_extract(d.d_day_name, '(\\w+)day', 1) AS day_root
FROM filtered_returns cr
JOIN date_dim d
  ON cr.cr_returned_date_sk = d.d_date_sk
WHERE d.d_holiday = 'Y'
  AND d.d_day_name LIKE '%day'
  AND regexp_like(d.d_day_name, '^S.*')
GROUP BY
    d.d_year,
    d.d_quarter_name,
    d.d_day_name,
    d.d_holiday
ORDER BY total_return_amount DESC
LIMIT 20
