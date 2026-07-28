SELECT
    i_color,
    COUNT(*) AS cnt,
    AVG(i_current_price) AS avg_price
FROM tpcds.item
WHERE i_rec_end_date = DATE '2000-10-26'
  AND i_color IN ('red', 'snow')
GROUP BY i_color
ORDER BY cnt DESC
LIMIT 100
