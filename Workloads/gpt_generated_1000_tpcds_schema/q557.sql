WITH sr_base AS (
   SELECT
       sr.sr_item_sk,
       sr.sr_return_quantity,
       sr.sr_return_amt,
       i.i_category,
       i.i_manufact_id,
       i.i_manager_id,
       i.i_color,
       i.i_item_sk,
       s.s_store_sk,
       s.s_state AS s_state,
       ca.ca_state AS ca_state,
       cd.cd_gender,
       cd.cd_credit_rating,
       cs.cs_quantity,
       cs.cs_net_paid,
       cs.cs_ext_tax,
       cs.cs_ext_ship_cost,
       cs.cs_net_profit,
       cc.cc_call_center_id,
       wr.wr_return_quantity,
       wr.wr_return_amt,
       ARRAY[i.i_category, i.i_color] AS cat_color_arr
   FROM
       store_returns sr TABLESAMPLE BERNOULLI (5)
       JOIN item i ON sr.sr_item_sk = i.i_item_sk
       JOIN store s ON sr.sr_store_sk = s.s_store_sk
       JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
       JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
       JOIN catalog_sales cs ON cs.cs_item_sk = i.i_item_sk
                            AND cs.cs_bill_cdemo_sk = cd.cd_demo_sk
       JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
       JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk
                            AND wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
   WHERE
       i.i_manufact_id IN (214, 460, 350)
       AND s.s_state = 'CA'
       AND cd.cd_credit_rating = 'Excellent'
),
union_all_data AS (
   SELECT * FROM sr_base
   UNION DISTINCT
   SELECT * FROM sr_base
   WHERE i_manager_id <> 21
),
agg AS (
   SELECT
       i_category,
       i_manufact_id,
       s_state,
       cd_gender,
       cat_or_color,
       SUM(cs_net_paid) AS total_net_paid,
       SUM(sr_return_amt) AS total_return_amt,
       AVG(cs_ext_tax) AS avg_ext_tax,
       COUNT(*) AS txn_count
   FROM union_all_data
   CROSS JOIN UNNEST(cat_color_arr) AS t(cat_or_color)
   GROUP BY ROLLUP (i_category, i_manufact_id, s_state, cd_gender, cat_or_color)
)
SELECT
   i_category,
   i_manufact_id,
   s_state,
   cd_gender,
   cat_or_color,
   total_net_paid,
   total_return_amt,
   avg_ext_tax,
   txn_count
FROM agg
WHERE total_net_paid > 10000
ORDER BY total_net_paid DESC
OFFSET 0 FETCH NEXT 100 ROWS ONLY
