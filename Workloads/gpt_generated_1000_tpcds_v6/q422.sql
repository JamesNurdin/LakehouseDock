WITH sales_agg AS (
   SELECT
       s.s_store_sk,
       s.s_store_id,
       s.s_store_name,
       s.s_state,
       SUM(ss.ss_ext_sales_price) AS total_sales,
       SUM(ss.ss_net_profit) AS total_profit,
       SUM(ss.ss_quantity) AS total_quantity
   FROM store_sales ss
   JOIN item i ON ss.ss_item_sk = i.i_item_sk
   JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
   JOIN store s ON ss.ss_store_sk = s.s_store_sk
   WHERE i.i_manufact_id IN (86, 294)
     AND cd.cd_gender = 'M'
     AND i.i_rec_start_date >= DATE '1999-01-01'
   GROUP BY s.s_store_sk, s.s_store_id, s.s_store_name, s.s_state
),
returns_agg AS (
   SELECT
       s.s_store_sk,
       SUM(sr.sr_return_amt_inc_tax) AS total_returns,
       SUM(sr.sr_net_loss) AS total_return_loss
   FROM store_returns sr
   JOIN store s ON sr.sr_store_sk = s.s_store_sk
   JOIN item i ON sr.sr_item_sk = i.i_item_sk
   JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
   WHERE i.i_manufact_id IN (86, 294)
     AND cd.cd_gender = 'M'
     AND i.i_rec_start_date >= DATE '1999-01-01'
   GROUP BY s.s_store_sk
)
SELECT
    sa.s_store_id,
    sa.s_store_name,
    sa.s_state,
    sa.total_sales,
    sa.total_profit,
    COALESCE(ra.total_returns, 0) AS total_returns,
    (sa.total_profit - COALESCE(ra.total_return_loss, 0)) AS net_profit_after_returns,
    RANK() OVER (PARTITION BY sa.s_state ORDER BY (sa.total_profit - COALESCE(ra.total_return_loss, 0)) DESC) AS profit_rank_state
FROM sales_agg sa
LEFT JOIN returns_agg ra ON sa.s_store_sk = ra.s_store_sk
WHERE sa.total_sales > 5000
ORDER BY sa.s_state, profit_rank_state
LIMIT 100
