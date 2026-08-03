WITH sales_union AS (
   SELECT
       cs.cs_item_sk AS item_sk,
       i.i_category,
       SUM(cs.cs_net_paid) AS net_paid,
       SUM(cs.cs_net_profit) AS net_profit,
       COUNT(*) AS sales_cnt
   FROM catalog_sales cs
   JOIN item i ON cs.cs_item_sk = i.i_item_sk
   WHERE cs.cs_sold_date_sk BETWEEN 2450000 AND 2453650
   GROUP BY cs.cs_item_sk, i.i_category
   UNION ALL
   SELECT
       ws.ws_item_sk AS item_sk,
       i.i_category,
       SUM(ws.ws_net_paid) AS net_paid,
       SUM(ws.ws_net_profit) AS net_profit,
       COUNT(*) AS sales_cnt
   FROM web_sales ws
   JOIN item i ON ws.ws_item_sk = i.i_item_sk
   WHERE ws.ws_sold_date_sk BETWEEN 2450000 AND 2453650
   GROUP BY ws.ws_item_sk, i.i_category
),
sales_agg AS (
   SELECT
       item_sk,
       i_category,
       SUM(net_paid) AS total_net_paid,
       SUM(net_profit) AS total_net_profit,
       SUM(sales_cnt) AS total_sales_cnt
   FROM sales_union
   GROUP BY item_sk, i_category
),
returns_filtered AS (
   SELECT
       cr.cr_item_sk AS item_sk,
       i.i_category,
       SUM(cr.cr_return_amount) AS total_return_amount,
       SUM(cr.cr_net_loss) AS total_net_loss
   FROM catalog_returns cr
   JOIN item i ON cr.cr_item_sk = i.i_item_sk
   WHERE NOT EXISTS (
       SELECT 1 FROM reason r WHERE r.r_reason_sk = cr.cr_reason_sk
   )
   GROUP BY cr.cr_item_sk, i.i_category
),
combined AS (
   SELECT
       COALESCE(s.item_sk, r.item_sk) AS item_sk,
       COALESCE(s.i_category, r.i_category) AS i_category,
       s.total_net_profit,
       r.total_net_loss
   FROM sales_agg s
   FULL OUTER JOIN returns_filtered r ON s.item_sk = r.item_sk
)
SELECT
   item_sk,
   i_category,
   total_net_profit,
   total_net_loss,
   rank
FROM (
   SELECT
       item_sk,
       i_category,
       total_net_profit,
       total_net_loss,
       ROW_NUMBER() OVER (PARTITION BY i_category ORDER BY total_net_profit DESC NULLS LAST) AS rank
   FROM combined
) ranked
WHERE rank <= 5
ORDER BY i_category, rank
LIMIT 100
