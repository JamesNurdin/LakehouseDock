/*
  Goal: Summarize combined catalog and web sales and returns by item brand and category for a specific ship‑customer, high store‑credit returns, a given manufacturer, and a California web site. The query aggregates revenue, return loss and transaction counts, ranks brands by net paid, and shows overall net paid for catalog and web channels.
*/
WITH joined_data AS (
    SELECT
        cs.cs_ship_customer_sk,
        cs.cs_net_paid,
        cs.cs_ext_discount_amt,
        cs.cs_ext_ship_cost,
        cr.cr_net_loss,
        cr.cr_store_credit,
        i.i_brand,
        i.i_category,
        i.i_manufact,
        ws.ws_net_paid,
        ws.ws_ext_ship_cost,
        wr.wr_net_loss,
        wsite.web_state
    FROM catalog_sales cs
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN catalog_returns cr
        ON cr.cr_item_sk = cs.cs_item_sk
        AND cr.cr_order_number = cs.cs_order_number
    JOIN web_sales ws
        ON ws.ws_item_sk = i.i_item_sk
    JOIN web_returns wr
        ON wr.wr_item_sk = ws.ws_item_sk
        AND wr.wr_order_number = ws.ws_order_number
    JOIN web_site wsite
        ON ws.ws_web_site_sk = wsite.web_site_sk
    WHERE cs.cs_ship_customer_sk = 4706359
      AND cr.cr_store_credit >= 500.00
      AND i.i_manufact = 'barprically'
      AND wsite.web_state = 'CA'
),
catalog_agg AS (
    SELECT
        i_brand,
        i_category,
        'Catalog' AS channel,
        SUM(cs_net_paid)               AS total_net_paid,
        SUM(cr_net_loss)               AS total_return_loss,
        COUNT(*)                       AS txn_cnt,
        AVG(cs_ext_discount_amt)       AS avg_metric,
        (SELECT SUM(cs2.cs_net_paid)
         FROM catalog_sales cs2
         WHERE cs2.cs_ship_customer_sk = 4706359) AS overall_net_paid
    FROM joined_data
    GROUP BY i_brand, i_category
),
web_agg AS (
    SELECT
        i_brand,
        i_category,
        'Web' AS channel,
        SUM(ws_net_paid)               AS total_net_paid,
        SUM(wr_net_loss)               AS total_return_loss,
        COUNT(*)                       AS txn_cnt,
        AVG(ws_ext_ship_cost)          AS avg_metric,
        (SELECT SUM(ws2.ws_net_paid)
         FROM web_sales ws2
         JOIN web_site wsite2 ON ws2.ws_web_site_sk = wsite2.web_site_sk
         WHERE wsite2.web_state = 'CA') AS overall_net_paid
    FROM joined_data
    GROUP BY i_brand, i_category
),
combined AS (
    SELECT * FROM catalog_agg
    UNION ALL
    SELECT * FROM web_agg
)
SELECT
    combined.i_brand,
    combined.i_category,
    combined.channel,
    combined.total_net_paid,
    combined.total_return_loss,
    combined.txn_cnt,
    combined.avg_metric,
    combined.overall_net_paid,
    ROW_NUMBER() OVER (PARTITION BY combined.i_brand ORDER BY combined.total_net_paid DESC) AS brand_rank
FROM combined
ORDER BY combined.i_brand, combined.total_net_paid DESC
LIMIT 100
