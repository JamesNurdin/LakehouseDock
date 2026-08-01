WITH filtered_catalog AS (
    SELECT
        cs.cs_item_sk AS item_sk,
        cs.cs_order_number AS order_number,
        cs.cs_sold_date_sk AS date_sk,
        cs.cs_net_profit AS net_profit,
        cs.cs_quantity AS quantity
    FROM catalog_sales cs
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    WHERE cc.cc_country = 'United States'
      AND cc.cc_call_center_sk IN (
          SELECT cc2.cc_call_center_sk
          FROM call_center cc2
          WHERE cc2.cc_gmt_offset <= -5.00
      )
      AND td.t_hour BETWEEN 8 AND 16
      AND cs.cs_net_profit > 0
      AND NOT EXISTS (
          SELECT 1
          FROM catalog_returns cr
          WHERE cr.cr_order_number = cs.cs_order_number
      )
),
filtered_store AS (
    SELECT
        ss.ss_item_sk AS item_sk,
        ss.ss_ticket_number AS order_number,
        ss.ss_sold_date_sk AS date_sk,
        ss.ss_net_profit AS net_profit,
        ss.ss_quantity AS quantity
    FROM store_sales ss
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    WHERE hd.hd_dep_count >= 5
      AND td.t_shift = 'Evening'
      AND ss.ss_net_profit > 0
      AND NOT EXISTS (
          SELECT 1
          FROM store_returns sr
          WHERE sr.sr_ticket_number = ss.ss_ticket_number
      )
),
combined_sales AS (
    SELECT
        item_sk,
        order_number,
        date_sk,
        net_profit,
        quantity,
        'catalog' AS channel
    FROM filtered_catalog
    UNION ALL
    SELECT
        item_sk,
        order_number,
        date_sk,
        net_profit,
        quantity,
        'store' AS channel
    FROM filtered_store
)
SELECT
    cs.item_sk,
    cs.order_number,
    cs.date_sk,
    cs.net_profit,
    cs.quantity,
    cs.channel
FROM combined_sales cs
WHERE cs.item_sk IN (
    SELECT cr.cr_item_sk
    FROM catalog_returns cr
    WHERE cr.cr_return_quantity > 0
)
ORDER BY cs.net_profit DESC
LIMIT 100
