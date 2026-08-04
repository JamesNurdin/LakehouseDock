/* goal: Identify top‑taxed store sales per hour, enriched with total return amount for the same sale date, while considering only afternoon minutes and high list prices, and ensuring the time keys exist in both sales and returns data. */
WITH ss_time AS (
    SELECT
        ss.ss_ticket_number,
        ss.ss_sold_date_sk,
        ss.ss_list_price,
        ss.ss_ext_tax,
        td.t_time_sk,
        td.t_hour,
        td.t_minute,
        td.t_am_pm
    FROM store_sales ss
    JOIN time_dim td
        ON ss.ss_sold_time_sk = td.t_time_sk
    WHERE td.t_minute IN (2, 8, 14)
      AND td.t_am_pm = 'PM'
      AND ss.ss_list_price > 50
),
cr_time AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_return_amount,
        td.t_time_sk,
        td.t_hour,
        td.t_minute,
        td.t_am_pm
    FROM catalog_returns cr
    JOIN time_dim td
        ON cr.cr_returned_time_sk = td.t_time_sk
    WHERE td.t_minute IN (2, 8, 14)
      AND td.t_am_pm = 'PM'
),
intersect_times AS (
    SELECT t_time_sk FROM (
        SELECT td.t_time_sk
        FROM store_sales ss
        JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    )
    INTERSECT
    SELECT t_time_sk FROM (
        SELECT td.t_time_sk
        FROM catalog_returns cr
        JOIN time_dim td ON cr.cr_returned_time_sk = td.t_time_sk
    )
)
SELECT
    ss_time.ss_ticket_number,
    ss_time.ss_sold_date_sk,
    ss_time.ss_list_price,
    ss_time.ss_ext_tax,
    ss_time.t_hour,
    ROW_NUMBER() OVER (PARTITION BY ss_time.t_hour ORDER BY ss_time.ss_ext_tax DESC) AS rn_hour_tax,
    (
        SELECT SUM(cr2.cr_return_amount)
        FROM catalog_returns cr2
        WHERE cr2.cr_returned_date_sk = ss_time.ss_sold_date_sk
    ) AS total_return_amount_for_date,
    COUNT(*) OVER (PARTITION BY ss_time.t_hour) AS cnt_per_hour
FROM ss_time
FULL OUTER JOIN cr_time
    ON ss_time.t_time_sk = cr_time.t_time_sk
WHERE ss_time.t_time_sk IN (SELECT t_time_sk FROM intersect_times)
   OR cr_time.t_time_sk IN (SELECT t_time_sk FROM intersect_times)
ORDER BY rn_hour_tax
LIMIT 100
