/*
Goal: Compare monthly return performance of physical stores versus web channels for the year 2002, broken down by item brand, and show total returned amount and count per month. The query uses a CTE to filter the date dimension, joins the appropriate fact tables, applies channel‑specific filters, and combines the results with UNION ALL.
*/
WITH filtered_dates AS (
    SELECT d_date_sk,
           d_year,
           d_month_seq
    FROM   date_dim
    WHERE  d_year = 2002
)
SELECT   return_channel,
         d_year,
         month_seq,
         brand,
         total_return_amount,
         return_count
FROM (
    SELECT
        'store' AS return_channel,
        fd.d_year,
        fd.d_month_seq AS month_seq,
        i.i_brand AS brand,
        SUM(sr.sr_return_amt_inc_tax) AS total_return_amount,
        COUNT(*) AS return_count
    FROM   store_returns sr
    JOIN   filtered_dates fd ON sr.sr_returned_date_sk = fd.d_date_sk
    JOIN   item i           ON sr.sr_item_sk = i.i_item_sk
    JOIN   store s          ON sr.sr_store_sk = s.s_store_sk
    WHERE  s.s_geography_class = 'Unknown'
    GROUP BY
        fd.d_year,
        fd.d_month_seq,
        i.i_brand

    UNION ALL

    SELECT
        'web' AS return_channel,
        fd.d_year,
        fd.d_month_seq AS month_seq,
        i.i_brand AS brand,
        SUM(wr.wr_return_amt_inc_tax) AS total_return_amount,
        COUNT(*) AS return_count
    FROM   web_returns wr
    JOIN   filtered_dates fd ON wr.wr_returned_date_sk = fd.d_date_sk
    JOIN   item i           ON wr.wr_item_sk = i.i_item_sk
    WHERE  i.i_current_price > 100
    GROUP BY
        fd.d_year,
        fd.d_month_seq,
        i.i_brand
) AS combined
ORDER BY
    return_channel,
    d_year,
    month_seq,
    total_return_amount DESC
LIMIT 100
