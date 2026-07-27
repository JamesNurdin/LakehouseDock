WITH sales_agg AS (
    SELECT i.i_brand AS brand,
           SUM(ss.ss_ext_sales_price) AS total_sales,
           SUM(ss.ss_net_profit) AS total_profit
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE i.i_rec_start_date >= DATE '1999-01-01'
      AND i.i_rec_end_date   <= DATE '2000-12-31'
      AND i.i_brand_id IN (2004002, 3002001)
    GROUP BY i.i_brand
),
returns_agg AS (
    SELECT i.i_brand AS brand,
           SUM(sr.sr_return_amt)   AS total_returns,
           SUM(sr.sr_refunded_cash) AS total_refunded
    FROM store_returns sr
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    WHERE i.i_rec_start_date >= DATE '1999-01-01'
      AND i.i_rec_end_date   <= DATE '2000-12-31'
      AND sr.sr_refunded_cash > 1000
    GROUP BY i.i_brand
)
SELECT brand,
       amount,
       source,
       metric
FROM (
    SELECT brand,
           total_sales      AS amount,
           'sales'          AS source,
           total_profit     AS metric
    FROM sales_agg
    UNION ALL
    SELECT brand,
           total_returns    AS amount,
           'returns'        AS source,
           total_refunded   AS metric
    FROM returns_agg
) combined
ORDER BY brand, source
