WITH sales_agg AS (
    SELECT s.date_sk,
           s.channel_sk,
           s.channel,
           SUM(s.net_profit) AS total_net_profit,
           SUM(s.net_paid) AS total_net_paid
    FROM (
        SELECT ss_sold_date_sk AS date_sk,
               ss_store_sk AS channel_sk,
               'Store' AS channel,
               ss_net_profit AS net_profit,
               ss_net_paid AS net_paid
        FROM store_sales
        UNION ALL
        SELECT cs_sold_date_sk AS date_sk,
               cs_call_center_sk AS channel_sk,
               'Catalog' AS channel,
               cs_net_profit AS net_profit,
               cs_net_paid AS net_paid
        FROM catalog_sales
        UNION ALL
        SELECT ws_sold_date_sk AS date_sk,
               ws_web_page_sk AS channel_sk,
               'Web' AS channel,
               ws_net_profit AS net_profit,
               ws_net_paid AS net_paid
        FROM web_sales
    ) s
    GROUP BY s.date_sk, s.channel_sk, s.channel
),
returns_agg AS (
    SELECT r.date_sk,
           r.channel_sk,
           SUM(r.net_loss) AS total_net_loss
    FROM (
        SELECT sr_returned_date_sk AS date_sk,
               sr_store_sk AS channel_sk,
               sr_net_loss AS net_loss
        FROM store_returns
        UNION ALL
        SELECT cr_returned_date_sk AS date_sk,
               cr_call_center_sk AS channel_sk,
               cr_net_loss AS net_loss
        FROM catalog_returns
        UNION ALL
        SELECT wr_returned_date_sk AS date_sk,
               wr_web_page_sk AS channel_sk,
               wr_net_loss AS net_loss
        FROM web_returns
    ) r
    GROUP BY r.date_sk, r.channel_sk
)
SELECT
    d.d_year,
    d.d_moy,
    s.channel,
    s.total_net_profit,
    COALESCE(r.total_net_loss, 0) AS total_net_loss,
    s.total_net_paid,
    s.total_net_profit - COALESCE(r.total_net_loss, 0) AS net_profit_after_returns
FROM sales_agg s
LEFT JOIN returns_agg r
  ON s.date_sk = r.date_sk AND s.channel_sk = r.channel_sk
JOIN date_dim d
  ON s.date_sk = d.d_date_sk
WHERE d.d_year = 2001
ORDER BY d.d_year, d.d_moy, s.channel
