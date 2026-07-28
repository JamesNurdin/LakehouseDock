WITH sr_base AS (
   SELECT
       sr.sr_item_sk,
       i.i_category,
       r.r_reason_desc,
       sr.sr_return_quantity AS return_qty,
       sr.sr_net_loss AS net_loss,
       c.c_customer_sk,
       ca.ca_state
   FROM store_returns sr
   JOIN item i ON sr.sr_item_sk = i.i_item_sk
   JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
   JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
   JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
   JOIN store s ON sr.sr_store_sk = s.s_store_sk
   WHERE i.i_units = 'Box'
     AND c.c_birth_year = 1975
     AND ca.ca_state = 'CA'
     AND s.s_state = 'CA'
),

wr_base AS (
   SELECT
       wr.wr_item_sk AS sr_item_sk,
       i.i_category,
       r.r_reason_desc,
       wr.wr_return_quantity AS return_qty,
       wr.wr_net_loss AS net_loss,
       c.c_customer_sk,
       ca.ca_state
   FROM web_returns wr
   JOIN item i ON wr.wr_item_sk = i.i_item_sk
   JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
   JOIN customer c ON wr.wr_refunded_customer_sk = c.c_customer_sk
   JOIN customer_address ca ON wr.wr_refunded_addr_sk = ca.ca_address_sk
   WHERE i.i_units = 'Box'
     AND c.c_birth_year = 1975
     AND ca.ca_state = 'CA'
),

union_returns AS (
   SELECT * FROM sr_base
   UNION ALL
   SELECT * FROM wr_base
),

catalog_agg AS (
   SELECT
       cr.cr_item_sk,
       SUM(cr.cr_net_loss) AS catalog_net_loss,
       sm.sm_code,
       r.r_reason_desc
   FROM catalog_returns cr
   JOIN item i ON cr.cr_item_sk = i.i_item_sk
   JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
   LEFT JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
   WHERE i.i_units = 'Box'
     AND sm.sm_code = 'AIR'
   GROUP BY cr.cr_item_sk, sm.sm_code, r.r_reason_desc
),

items_with_catalog_loss AS (
   SELECT DISTINCT cr_item_sk
   FROM catalog_returns
   WHERE cr_net_loss > 0
)

SELECT
   ur.i_category,
   ur.r_reason_desc,
   COUNT(DISTINCT ur.c_customer_sk) AS distinct_customers,
   SUM(ur.return_qty) AS total_return_qty,
   SUM(ur.net_loss) AS total_channel_net_loss,
   COALESCE(ca.catalog_net_loss, 0) AS total_catalog_net_loss,
   ca.sm_code
FROM union_returns ur
LEFT JOIN catalog_agg ca
   ON ur.sr_item_sk = ca.cr_item_sk
WHERE NOT EXISTS (
   SELECT 1 FROM items_with_catalog_loss iwl
   WHERE iwl.cr_item_sk = ur.sr_item_sk
)
GROUP BY
   ur.i_category,
   ur.r_reason_desc,
   ca.catalog_net_loss,
   ca.sm_code
ORDER BY total_channel_net_loss DESC
LIMIT 100
