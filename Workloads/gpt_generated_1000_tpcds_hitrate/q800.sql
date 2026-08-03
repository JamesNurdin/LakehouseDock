WITH sales_agg AS (
   SELECT
       i.i_item_sk AS item_sk,
       i.i_item_id,
       CONCAT('Item-', i.i_item_id) AS item_label,
       i.i_product_name,
       regexp_extract(i.i_product_name, '(\\d+)', 1) AS prod_num,
       hd.hd_buy_potential,
       SUM(ws.ws_ext_sales_price) AS total_sales,
       SUM(ws.ws_net_profit) AS total_profit,
       COUNT(*) AS sales_cnt
   FROM web_sales ws
   JOIN item i ON ws.ws_item_sk = i.i_item_sk
   JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
   WHERE regexp_like(i.i_product_name, '^[A-Z]{2}[0-9]{3}')
     AND i.i_product_name LIKE '%Premium%'
   GROUP BY
       i.i_item_sk,
       i.i_item_id,
       i.i_product_name,
       hd.hd_buy_potential
),
refund_agg AS (
   SELECT
       i.i_item_sk AS item_sk,
       AVG(sr.sr_refunded_cash) AS avg_refund
   FROM store_returns sr
   JOIN item i ON sr.sr_item_sk = i.i_item_sk
   WHERE sr.sr_refunded_cash > 100
   GROUP BY i.i_item_sk
)
-- First branch of the UNION
SELECT DISTINCT
   sa.item_sk,
   sa.item_label,
   sa.prod_num,
   sa.total_sales,
   sa.total_profit,
   sa.sales_cnt,
   sa.hd_buy_potential,
   ra.avg_refund
FROM sales_agg sa
JOIN refund_agg ra ON sa.item_sk = ra.item_sk

UNION DISTINCT

-- Second branch of the UNION
SELECT DISTINCT
   i.i_item_sk AS item_sk,
   CONCAT('Item-', i.i_item_id) AS item_label,
   regexp_extract(i.i_product_name, '(\\d+)', 1) AS prod_num,
   0.0 AS total_sales,
   0.0 AS total_profit,
   0 AS sales_cnt,
   hd.hd_buy_potential,
   (
       SELECT AVG(sr2.sr_refunded_cash)
       FROM store_returns sr2
       WHERE sr2.sr_item_sk = i.i_item_sk
   ) AS avg_refund
FROM item i
JOIN store_returns sr3 ON sr3.sr_item_sk = i.i_item_sk
JOIN household_demographics hd ON sr3.sr_hdemo_sk = hd.hd_demo_sk
WHERE i.i_product_name LIKE '%Standard%'

ORDER BY total_sales DESC
LIMIT 100
