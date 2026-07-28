WITH sr_agg AS (
   SELECT
      i.i_item_sk,
      i.i_category,
      cd.cd_gender,
      SUM(sr.sr_return_quantity) AS total_quantity,
      SUM(sr.sr_return_amt) AS total_amount,
      COUNT(*) AS cnt_returns
   FROM store_returns sr
   JOIN item i ON sr.sr_item_sk = i.i_item_sk
   JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
   GROUP BY i.i_item_sk, i.i_category, cd.cd_gender
)
SELECT
   cr.cr_order_number,
   i1.i_brand,
   cd_ref.cd_gender AS refunded_gender,
   cd_ret.cd_marital_status AS returning_marital_status,
   sm.sm_type,
   sr_agg.i_category,
   sr_agg.cd_gender,
   COUNT(DISTINCT sr_agg.i_item_sk) AS distinct_items,
   SUM(cr.cr_net_loss) AS total_net_loss,
   AVG(cr.cr_fee) AS avg_fee
FROM sr_agg
JOIN item i2 ON sr_agg.i_item_sk = i2.i_item_sk                                   -- join 1 (derived to item)
JOIN catalog_returns cr ON cr.cr_item_sk = i2.i_item_sk                           -- join 2
JOIN item i1 ON cr.cr_item_sk = i1.i_item_sk                                       -- join 3 (second item alias)
JOIN customer_demographics cd_ref ON cr.cr_refunded_cdemo_sk = cd_ref.cd_demo_sk  -- join 4
JOIN customer_demographics cd_ret ON cr.cr_returning_cdemo_sk = cd_ret.cd_demo_sk  -- join 5
JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk                       -- join 6
JOIN ship_mode sm2 ON cr.cr_ship_mode_sk = sm2.sm_ship_mode_sk                     -- join 7 (second ship_mode alias)
JOIN ship_mode sm3 ON cr.cr_ship_mode_sk = sm3.sm_ship_mode_sk                     -- join 8 (third ship_mode alias)
JOIN catalog_returns cr2 ON cr2.cr_item_sk = i1.i_item_sk                         -- join 9 (second catalog_returns alias)
GROUP BY
   cr.cr_order_number,
   i1.i_brand,
   cd_ref.cd_gender,
   cd_ret.cd_marital_status,
   sm.sm_type,
   sr_agg.i_category,
   sr_agg.cd_gender
HAVING SUM(cr.cr_net_loss) > 0
ORDER BY total_net_loss DESC
LIMIT 100
