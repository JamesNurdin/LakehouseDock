WITH
  store_return_counts AS (
    SELECT sr_item_sk, COUNT(*) AS return_count
    FROM store_returns
    GROUP BY sr_item_sk
  ),
  web_return_counts AS (
    SELECT wr_item_sk, COUNT(*) AS return_count
    FROM web_returns
    GROUP BY wr_item_sk
  ),
  store_sales_summary AS (
    SELECT i.i_item_id,
           i.i_item_desc,
           i.i_item_sk,
           SUM(ss.ss_net_profit) AS total_net_profit,
           'store' AS source
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE p.p_discount_active = 'Y'
      AND EXISTS (
        SELECT 1
        FROM store_returns sr2
        JOIN reason r ON sr2.sr_reason_sk = r.r_reason_sk
        WHERE sr2.sr_item_sk = ss.ss_item_sk
          AND r.r_reason_desc LIKE '%color%'
      )
    GROUP BY i.i_item_id, i.i_item_desc, i.i_item_sk
  ),
  web_sales_summary AS (
    SELECT i.i_item_id,
           i.i_item_desc,
           i.i_item_sk,
           SUM(ws.ws_net_profit) AS total_net_profit,
           'web' AS source
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    LEFT JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE p.p_discount_active = 'Y'
      AND EXISTS (
        SELECT 1
        FROM web_returns wr2
        JOIN reason r ON wr2.wr_reason_sk = r.r_reason_sk
        WHERE wr2.wr_item_sk = ws.ws_item_sk
          AND r.r_reason_desc LIKE '%color%'
      )
    GROUP BY i.i_item_id, i.i_item_desc, i.i_item_sk
  ),
  store_sales_agg AS (
    SELECT sss.i_item_id,
           sss.i_item_desc,
           sss.total_net_profit,
           sss.source,
           COALESCE(src.return_count, 0) AS return_count
    FROM store_sales_summary sss
    LEFT JOIN store_return_counts src ON sss.i_item_sk = src.sr_item_sk
  ),
  web_sales_agg AS (
    SELECT wss.i_item_id,
           wss.i_item_desc,
           wss.total_net_profit,
           wss.source,
           COALESCE(wrc.return_count, 0) AS return_count
    FROM web_sales_summary wss
    LEFT JOIN web_return_counts wrc ON wss.i_item_sk = wrc.wr_item_sk
  )
SELECT i_item_id,
       i_item_desc,
       total_net_profit,
       source,
       return_count
FROM store_sales_agg
UNION ALL
SELECT i_item_id,
       i_item_desc,
       total_net_profit,
       source,
       return_count
FROM web_sales_agg
ORDER BY total_net_profit DESC
LIMIT 100
