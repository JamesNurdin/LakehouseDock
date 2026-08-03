WITH sampled_sales AS (
   SELECT
       ss.ss_item_sk,
       ss.ss_quantity,
       ss.ss_net_paid,
       ss.ss_sold_date_sk
   FROM store_sales ss
   TABLESAMPLE BERNOULLI (5)
   WHERE ss.ss_sold_date_sk BETWEEN 2450800 AND 2450900
),
store_agg AS (
   SELECT
       s.ss_item_sk AS item_sk,
       i.i_item_id AS item_id,
       s.ss_quantity AS qty,
       s.ss_net_paid AS net_paid,
       l.total_qty
   FROM sampled_sales s
   JOIN item i ON s.ss_item_sk = i.i_item_sk
   CROSS JOIN LATERAL (
       SELECT sum(ss2.ss_quantity) AS total_qty
       FROM store_sales ss2
       WHERE ss2.ss_item_sk = s.ss_item_sk
   ) l
),
web_agg AS (
   SELECT
       ws.ws_item_sk AS item_sk,
       i.i_item_id AS item_id,
       sum(ws.ws_quantity) AS web_quantity,
       sum(ws.ws_net_paid) AS web_net_paid
   FROM web_sales ws
   JOIN item i ON ws.ws_item_sk = i.i_item_sk
   WHERE ws.ws_sold_date_sk BETWEEN 2450800 AND 2450900
   GROUP BY ws.ws_item_sk, i.i_item_id
),
store_web_full AS (
   SELECT
       coalesce(sa.item_sk, wa.item_sk) AS item_sk,
       coalesce(sa.item_id, wa.item_id) AS item_id,
       sa.qty,
       sa.net_paid,
       sa.total_qty,
       wa.web_quantity,
       wa.web_net_paid
   FROM store_agg sa
   FULL OUTER JOIN web_agg wa ON sa.item_sk = wa.item_sk
)
SELECT
   fw.item_sk,
   fw.item_id,
   fw.qty,
   fw.net_paid,
   fw.total_qty,
   fw.web_quantity,
   fw.web_net_paid
FROM store_web_full fw

UNION ALL

SELECT
   cr.cr_item_sk AS item_sk,
   i.i_item_id AS item_id,
   cr.cr_return_quantity AS qty,
   cr.cr_return_amount AS net_paid,
   null AS total_qty,
   null AS web_quantity,
   null AS web_net_paid
FROM catalog_returns cr
JOIN item i ON cr.cr_item_sk = i.i_item_sk
WHERE cr.cr_returned_date_sk BETWEEN 2450800 AND 2450900

ORDER BY item_sk
LIMIT 100
