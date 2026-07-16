SELECT d.d_date,
       i.i_item_id,
       i.i_item_desc,
       SUM(ev.profit) AS total_profit
FROM (
    SELECT cs_sold_date_sk AS date_sk, cs_item_sk AS item_sk, cs_net_profit AS profit
    FROM catalog_sales
    UNION ALL
    SELECT ss_sold_date_sk, ss_item_sk, ss_net_profit
    FROM store_sales
    UNION ALL
    SELECT ws_sold_date_sk, ws_item_sk, ws_net_profit
    FROM web_sales
    UNION ALL
    SELECT cr_returned_date_sk, cr_item_sk, -cr_net_loss
    FROM catalog_returns
    UNION ALL
    SELECT sr_returned_date_sk, sr_item_sk, -sr_net_loss
    FROM store_returns
    UNION ALL
    SELECT wr_returned_date_sk, wr_item_sk, -wr_net_loss
    FROM web_returns
) ev
JOIN date_dim d ON ev.date_sk = d.d_date_sk
JOIN item i ON ev.item_sk = i.i_item_sk
GROUP BY d.d_date, i.i_item_id, i.i_item_desc
ORDER BY total_profit DESC
LIMIT 100
