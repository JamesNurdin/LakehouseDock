WITH date_filtered AS (
    SELECT
        d_date_sk,
        d_year,
        d_day_name,
        d_month_seq,
        d_holiday,
        CONCAT(d_day_name, '_', CAST(d_month_seq AS VARCHAR)) AS day_month_key,
        SUBSTRING(d_day_name, 1, 3) AS day_abbr,
        regexp_extract(d_holiday, '^(.*) DAY$', 1) AS holiday_name
    FROM date_dim
    WHERE
        CONCAT(d_day_name, '_', CAST(d_month_seq AS VARCHAR)) LIKE 'S%_%'
        AND regexp_like(d_holiday, '^.* DAY$')
        AND d_current_month = 'Y'
)
SELECT
    df.d_year,
    df.day_abbr,
    df.holiday_name,
    COUNT(DISTINCT cs.cs_order_number) AS orders,
    SUM(cs.cs_net_profit) AS net_profit,
    SUM(sr.sr_return_amt) AS total_return,
    SUM(inv.inv_quantity_on_hand) AS inventory_qty
FROM date_filtered df
LEFT JOIN catalog_sales cs ON cs.cs_sold_date_sk = df.d_date_sk
LEFT JOIN store_returns sr ON sr.sr_returned_date_sk = df.d_date_sk
LEFT JOIN inventory inv ON inv.inv_date_sk = df.d_date_sk
GROUP BY df.d_year, df.day_abbr, df.holiday_name
ORDER BY df.d_year DESC, net_profit DESC
LIMIT 100
