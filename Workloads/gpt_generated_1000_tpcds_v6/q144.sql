WITH base AS (
  SELECT
    s.s_store_name,
    s.s_state,
    we.web_name,
    we.web_site_sk,
    i.i_item_id,
    i.i_product_name,
    i.i_current_price,
    i.i_brand_id,
    inv.inv_quantity_on_hand,
    r.r_reason_desc,
    r.r_reason_id,
    sr.sr_return_quantity,
    sr.sr_net_loss,
    ws.ws_net_profit,
    ws.ws_item_sk,
    ws.ws_sold_date_sk,
    ws.ws_ext_sales_price
  FROM store_returns sr
  JOIN item i ON sr.sr_item_sk = i.i_item_sk
  JOIN store s ON sr.sr_store_sk = s.s_store_sk
  JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
  JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
  JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
  JOIN web_site we ON ws.ws_web_site_sk = we.web_site_sk
  WHERE i.i_current_price > 20
    AND i.i_brand_id IN (1, 2, 3)
    AND s.s_state = 'CA'
    AND we.web_company_id = 3
    AND inv.inv_quantity_on_hand > 0
    AND r.r_reason_id LIKE 'AAAAAAA%'
    AND EXISTS (
        SELECT 1 FROM reason r2
        WHERE r2.r_reason_sk = sr.sr_reason_sk
          AND r2.r_reason_desc LIKE '%damaged%'
    )
)
SELECT
  s_store_name,
  s_state,
  web_name,
  i_item_id,
  i_product_name,
  r_reason_desc,
  SUM(sr_net_loss) AS total_return_loss,
  SUM(ws_net_profit) AS total_web_profit,
  COUNT(DISTINCT sr_return_quantity) AS distinct_return_qty,
  (SELECT AVG(ws2.ws_net_profit)
   FROM web_sales ws2
   WHERE ws2.ws_item_sk = base.ws_item_sk) AS avg_item_profit,
  RANK() OVER (PARTITION BY s_store_name ORDER BY SUM(ws_net_profit) DESC) AS profit_rank
FROM base
GROUP BY
  s_store_name,
  s_state,
  web_name,
  i_item_id,
  i_product_name,
  r_reason_desc,
  base.ws_item_sk
HAVING SUM(sr_net_loss) > 1000
   AND SUM(ws_net_profit) > 500
ORDER BY profit_rank, total_web_profit DESC
LIMIT 100
