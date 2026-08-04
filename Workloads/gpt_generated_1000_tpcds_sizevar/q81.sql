WITH filtered_dates AS (
    SELECT d_date_sk,
           d_date,
           d_year
    FROM tpcds.date_dim
    WHERE d_year = 2001
),
catalog_part AS (
    SELECT
        cs.cs_order_number            AS transaction_id,
        cs.cs_net_paid                AS amount,
        d.d_date                      AS transaction_date,
        i.i_product_name              AS product,
        'Catalog'                     AS source,
        (SELECT AVG(cs2.cs_net_paid)
         FROM tpcds.catalog_sales cs2
         WHERE cs2.cs_sold_date_sk = d.d_date_sk) AS avg_daily_amount
    FROM tpcds.catalog_sales cs
    JOIN filtered_dates d
      ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN tpcds.item i
      ON cs.cs_item_sk = i.i_item_sk
    JOIN tpcds.call_center cc
      ON cs.cs_call_center_sk = cc.cc_call_center_sk
    WHERE cs.cs_net_paid > 500
      AND EXISTS (
          SELECT 1
          FROM tpcds.warehouse w
          WHERE cs.cs_warehouse_sk = w.w_warehouse_sk
            AND w.w_city = 'Los Angeles'
      )
),
return_part AS (
    SELECT
        sr.sr_ticket_number           AS transaction_id,
        sr.sr_return_amt              AS amount,
        d.d_date                      AS transaction_date,
        i.i_product_name              AS product,
        'Return'                      AS source,
        (SELECT AVG(sr2.sr_return_amt)
         FROM tpcds.store_returns sr2
         WHERE sr2.sr_returned_date_sk = d.d_date_sk) AS avg_daily_amount
    FROM tpcds.store_returns sr
    JOIN filtered_dates d
      ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN tpcds.item i
      ON sr.sr_item_sk = i.i_item_sk
    JOIN tpcds.reason r
      ON sr.sr_reason_sk = r.r_reason_sk
    WHERE sr.sr_return_amt > 100
      AND EXISTS (
          SELECT 1
          FROM tpcds.store_returns sr3
          WHERE sr3.sr_item_sk = i.i_item_sk
            AND sr3.sr_returned_date_sk = d.d_date_sk
            AND sr3.sr_return_amt > 200
      )
)
SELECT *
FROM (
    SELECT * FROM catalog_part
    UNION ALL
    SELECT * FROM return_part
) AS combined
ORDER BY transaction_date DESC,
         amount DESC
OFFSET 0 LIMIT 100
