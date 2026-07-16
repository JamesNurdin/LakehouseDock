WITH store_agg AS (
  SELECT ca.ca_state AS state,
         ss.ss_item_sk AS item_sk,
         SUM(ss.ss_net_paid_inc_tax) AS store_sales_amount,
         SUM(ss.ss_net_profit) AS store_profit
  FROM store_sales ss
  JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
  GROUP BY ca.ca_state, ss.ss_item_sk
),
store_ret_agg AS (
  SELECT ca.ca_state AS state,
         sr.sr_item_sk AS item_sk,
         SUM(sr.sr_return_quantity) AS return_qty,
         SUM(sr.sr_net_loss) AS return_loss
  FROM store_returns sr
  JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
  GROUP BY ca.ca_state, sr.sr_item_sk
),
catalog_ret_agg AS (
  SELECT ca.ca_state AS state,
         cr.cr_item_sk AS item_sk,
         SUM(cr.cr_return_quantity) AS cat_return_qty,
         SUM(cr.cr_net_loss) AS cat_return_loss
  FROM catalog_returns cr
  JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
  JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
  WHERE cp.cp_type = 'monthly'
  GROUP BY ca.ca_state, cr.cr_item_sk
),
web_agg AS (
  SELECT ca.ca_state AS state,
         ws.ws_item_sk AS item_sk,
         SUM(ws.ws_net_paid_inc_tax) AS web_sales_amount,
         SUM(ws.ws_net_profit) AS web_profit
  FROM web_sales ws
  JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
  JOIN web_site wsit ON ws.ws_web_site_sk = wsit.web_site_sk
  WHERE wsit.web_state = 'CA'
  GROUP BY ca.ca_state, ws.ws_item_sk
)
SELECT COALESCE(s.state, r.state, c.state, w.state) AS state,
       COALESCE(s.item_sk, r.item_sk, c.item_sk, w.item_sk) AS item_sk,
       COALESCE(s.store_sales_amount, 0) AS store_sales_amount,
       COALESCE(s.store_profit, 0) AS store_profit,
       COALESCE(r.return_qty, 0) AS store_return_qty,
       COALESCE(r.return_loss, 0) AS store_return_loss,
       COALESCE(c.cat_return_qty, 0) AS catalog_return_qty,
       COALESCE(c.cat_return_loss, 0) AS catalog_return_loss,
       COALESCE(w.web_sales_amount, 0) AS web_sales_amount,
       COALESCE(w.web_profit, 0) AS web_profit,
       (COALESCE(s.store_profit, 0) - COALESCE(r.return_loss, 0) - COALESCE(c.cat_return_loss, 0) + COALESCE(w.web_profit, 0)) AS net_total_profit
FROM store_agg s
FULL OUTER JOIN store_ret_agg r ON s.state = r.state AND s.item_sk = r.item_sk
FULL OUTER JOIN catalog_ret_agg c ON COALESCE(s.state, r.state) = c.state AND COALESCE(s.item_sk, r.item_sk) = c.item_sk
FULL OUTER JOIN web_agg w ON COALESCE(s.state, r.state, c.state) = w.state AND COALESCE(s.item_sk, r.item_sk, c.item_sk) = w.item_sk
WHERE (COALESCE(s.store_sales_amount, 0) + COALESCE(w.web_sales_amount, 0)) > 1000
ORDER BY net_total_profit DESC
LIMIT 100
