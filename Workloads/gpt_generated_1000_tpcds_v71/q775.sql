SELECT
    t_shift,
    t_hour,
    total_sales,
    total_quantity
FROM (
    SELECT
        td.t_shift,
        td.t_hour,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_quantity) AS total_quantity
    FROM store_sales ss
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    WHERE td.t_shift = 'first'
      AND td.t_hour BETWEEN 8 AND 12
    GROUP BY td.t_shift, td.t_hour

    UNION ALL

    SELECT
        td.t_shift,
        td.t_hour,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_quantity) AS total_quantity
    FROM store_sales ss
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    WHERE td.t_shift = 'second'
      AND td.t_hour BETWEEN 14 AND 18
    GROUP BY td.t_shift, td.t_hour
) AS combined
ORDER BY t_shift, t_hour
LIMIT 100
