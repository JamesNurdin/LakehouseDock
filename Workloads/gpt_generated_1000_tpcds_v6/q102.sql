WITH filtered_time AS (
    SELECT
        t_time_sk,
        t_time_id,
        t_hour,
        t_minute,
        t_sub_shift,
        regexp_extract(t_time_id, '(......)(.)', 2) AS extracted_char,
        CASE WHEN t_sub_shift LIKE '%morning%' THEN 1 ELSE 0 END AS is_morning
    FROM time_dim
    WHERE regexp_like(t_time_id, '^A{8}B')
      AND t_sub_shift LIKE '%morning%'
)
SELECT
    ft.t_hour,
    ft.t_sub_shift,
    COUNT(wr.wr_order_number) AS return_orders,
    SUM(wr.wr_return_amt) AS total_return_amount,
    AVG(wr.wr_fee) AS avg_fee,
    SUM(wr.wr_return_amt_inc_tax) - SUM(wr.wr_return_tax) AS net_return_without_tax,
    CONCAT('Hour_', CAST(ft.t_hour AS varchar), '_', ft.t_sub_shift) AS period_label,
    ft.extracted_char
FROM web_returns wr
JOIN filtered_time ft
    ON wr.wr_returned_time_sk = ft.t_time_sk
WHERE wr.wr_fee > 10
  AND wr.wr_return_amt_inc_tax > 0
GROUP BY
    ft.t_hour,
    ft.t_sub_shift,
    ft.extracted_char
ORDER BY total_return_amount DESC
LIMIT 100
