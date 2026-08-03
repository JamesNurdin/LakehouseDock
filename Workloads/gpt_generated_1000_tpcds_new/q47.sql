WITH base AS (
    SELECT
        d.d_date,
        d.d_year,
        d.d_month_seq,
        ss.ss_sold_date_sk,
        ss.ss_item_sk,
        ss.ss_ticket_number,
        ss.ss_ext_sales_price,
        ss.ss_sales_price,
        ss.ss_quantity,
        sr.sr_returned_date_sk,
        sr.sr_item_sk,
        sr.sr_ticket_number,
        sr.sr_return_amt_inc_tax,
        sr.sr_store_credit,
        inv.inv_quantity_on_hand,
        ARRAY[ss.ss_sales_price, ss.ss_ext_sales_price] AS price_array
    FROM tpcds.date_dim d
    JOIN tpcds.store_sales ss
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN tpcds.store_returns sr
        ON sr.sr_returned_date_sk = d.d_date_sk
        AND sr.sr_item_sk = ss.ss_item_sk
        AND sr.sr_ticket_number = ss.ss_ticket_number
    JOIN tpcds.inventory inv
        ON inv.inv_date_sk = d.d_date_sk
)
SELECT
    d_year,
    d_month_seq,
    SUM(ss_ext_sales_price) AS total_sales,
    SUM(sr_return_amt_inc_tax) AS total_return_inc_tax,
    COUNT(DISTINCT ss_ticket_number) AS distinct_tickets,
    SUM(price) AS sum_price_unnested
FROM base
CROSS JOIN UNNEST(price_array) AS t(price)
WHERE d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
  AND inv_quantity_on_hand > 0
  AND sr_store_credit > 20
GROUP BY ROLLUP (d_year, d_month_seq)
ORDER BY d_year, d_month_seq
LIMIT 100
