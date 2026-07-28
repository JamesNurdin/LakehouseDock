/*
Goal: Compare total net loss from catalog returns and web returns by item brand, showing the combined top losses across both channels.
*/
SELECT
  item_id,
  brand,
  total_net_loss,
  return_channel
FROM (
  SELECT
    i.i_item_id AS item_id,
    i.i_brand AS brand,
    SUM(cr.cr_net_loss) AS total_net_loss,
    'catalog' AS return_channel
  FROM tpcds.catalog_returns cr
  JOIN tpcds.item i ON cr.cr_item_sk = i.i_item_sk
  JOIN tpcds.promotion p ON p.p_item_sk = i.i_item_sk
  WHERE p.p_channel_radio = 'N'
  GROUP BY i.i_item_id, i.i_brand

  UNION ALL

  SELECT
    i.i_item_id AS item_id,
    i.i_brand AS brand,
    SUM(wr.wr_net_loss) AS total_net_loss,
    'web' AS return_channel
  FROM tpcds.web_returns wr
  JOIN tpcds.item i ON wr.wr_item_sk = i.i_item_sk
  JOIN tpcds.promotion p ON p.p_item_sk = i.i_item_sk
  WHERE p.p_channel_radio = 'N'
  GROUP BY i.i_item_id, i.i_brand
) AS combined
ORDER BY total_net_loss DESC
LIMIT 100
