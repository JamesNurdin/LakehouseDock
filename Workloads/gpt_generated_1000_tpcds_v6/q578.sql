WITH
  -- store returns joined to their address (required join rule)
  store_ret AS (
    SELECT
      sr.sr_customer_sk,
      sr.sr_return_quantity,
      sr.sr_return_amt,
      sr.sr_net_loss,
      ca.ca_address_sk
    FROM store_returns sr
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    WHERE sr.sr_return_quantity > 0
  ),
  -- base join of the seven selected tables using only the allowed keys
  joined AS (
    SELECT
      cc.cc_name,
      sm.sm_type,
      cs.cs_net_profit,
      cr.cr_net_loss,
      ws.ws_net_profit,
      sr.sr_net_loss,
      cs.cs_quantity
    FROM catalog_sales cs
    JOIN call_center cc
      ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm
      ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN catalog_returns cr
      ON cr.cr_order_number = cs.cs_order_number
     AND cr.cr_item_sk = cs.cs_item_sk
    JOIN customer_address ca_bill
      ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
    JOIN customer_address ca_ship
      ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
    JOIN customer_address ca_refund
      ON cr.cr_refunded_addr_sk = ca_refund.ca_address_sk
    JOIN customer_address ca_returning
      ON cr.cr_returning_addr_sk = ca_returning.ca_address_sk
    JOIN web_sales ws
      ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN store_ret sr
      ON 1 = 1  -- cross‑join; store_ret already contains its required address join
    WHERE
      cc.cc_manager = 'Clyde Scott'
      AND cc.cc_rec_end_date = DATE '2001-12-31'
      AND sm.sm_type = 'EXPRESS'
      AND ca_bill.ca_county = 'Maricopa County'
      AND cs.cs_quantity > 5
      AND ws.ws_net_profit > 0
  ),
  -- aggregation with grouping sets to obtain subtotals
  aggregated AS (
    SELECT
      cc_name,
      sm_type,
      SUM(cs_net_profit)                AS catalog_sales_profit,
      SUM(cr_net_loss)                  AS catalog_returns_loss,
      SUM(ws_net_profit)                AS web_sales_profit,
      SUM(sr_net_loss)                  AS store_returns_loss,
      (
        SELECT MAX(cs2.cs_quantity)
        FROM catalog_sales cs2
        JOIN call_center cc2 ON cs2.cs_call_center_sk = cc2.cc_call_center_sk
        WHERE cc2.cc_name = joined.cc_name
      )                                 AS max_quantity_per_center
    FROM joined
    GROUP BY GROUPING SETS (
      (cc_name, sm_type),
      (cc_name),
      (sm_type),
      ()
    )
  )
SELECT
  cc_name,
  sm_type,
  catalog_sales_profit,
  catalog_returns_loss,
  web_sales_profit,
  store_returns_loss,
  max_quantity_per_center,
  RANK() OVER (PARTITION BY cc_name ORDER BY (catalog_sales_profit - catalog_returns_loss + web_sales_profit - store_returns_loss) DESC) AS profit_rank,
  CASE
    WHEN catalog_sales_profit > 10000 THEN 'HIGH'
    WHEN catalog_sales_profit > 5000  THEN 'MEDIUM'
    ELSE 'LOW'
  END AS profit_category
FROM aggregated
ORDER BY profit_rank, cc_name
