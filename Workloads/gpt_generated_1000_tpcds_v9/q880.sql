WITH catalog_sales_data AS (
    SELECT
        i.i_item_id AS item_id,
        d.d_date AS sale_date,
        'Catalog' AS channel,
        SUM(cs.cs_net_paid) AS net_paid
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE d.d_year = 2000
      AND sm.sm_type = 'NEXT DAY'
      AND NOT EXISTS (
          SELECT 1
          FROM store_returns sr
          WHERE sr.sr_item_sk = i.i_item_sk
            AND sr.sr_returned_date_sk = d.d_date_sk
      )
    GROUP BY i.i_item_id, d.d_date
),
store_sales_data AS (
    SELECT
        i.i_item_id AS item_id,
        d.d_date AS sale_date,
        'Store' AS channel,
        SUM(ss.ss_net_paid) AS net_paid
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE d.d_year = 2000
      AND NOT EXISTS (
          SELECT 1
          FROM store_returns sr
          WHERE sr.sr_ticket_number = ss.ss_ticket_number
            AND sr.sr_item_sk = ss.ss_item_sk
            AND sr.sr_returned_date_sk = d.d_date_sk
      )
    GROUP BY i.i_item_id, d.d_date
)
SELECT DISTINCT
    combined.item_id,
    combined.sale_date,
    combined.channel,
    combined.net_paid
FROM (
    SELECT item_id, sale_date, channel, net_paid
    FROM catalog_sales_data
    UNION ALL
    SELECT item_id, sale_date, channel, net_paid
    FROM store_sales_data
) AS combined
ORDER BY combined.net_paid DESC
LIMIT 100
