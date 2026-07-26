SELECT
    c.c_customer_id,
    hd.hd_vehicle_count,
    ds_ship.d_date AS ship_date,
    ds_sales.d_date AS sales_date,
    DATE_DIFF('day', ds_ship.d_date, ds_sales.d_date) AS days_between,
    CASE
        WHEN c.c_birth_year BETWEEN 1900 AND 1949 THEN 'Silent Generation'
        WHEN c.c_birth_year BETWEEN 1950 AND 1969 THEN 'Baby Boomer'
        WHEN c.c_birth_year BETWEEN 1970 AND 1989 THEN 'Gen X'
        WHEN c.c_birth_year BETWEEN 1990 AND 2009 THEN 'Gen Y'
        ELSE 'Gen Z'
    END AS generation,
    DENSE_RANK() OVER (PARTITION BY hd.hd_vehicle_count ORDER BY DATE_DIFF('day', ds_ship.d_date, ds_sales.d_date) DESC) AS vehicle_rank
FROM customer c
JOIN date_dim ds_ship ON c.c_first_shipto_date_sk = ds_ship.d_date_sk
JOIN date_dim ds_sales ON c.c_first_sales_date_sk = ds_sales.d_date_sk
JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
WHERE ds_ship.d_date IS NOT NULL
  AND ds_sales.d_date IS NOT NULL
ORDER BY c.c_customer_id
LIMIT 100
