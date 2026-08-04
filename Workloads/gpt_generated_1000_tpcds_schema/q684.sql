WITH sampled_sales AS (
   SELECT *
   FROM web_sales
   TABLESAMPLE BERNOULLI (10)
   WHERE ws_quantity > 1
     AND ws_ext_sales_price > 100
     AND ws_ext_discount_amt < 50
),
full_promo AS (
   SELECT
       ss.ws_order_number,
       ss.ws_item_sk,
       ss.ws_warehouse_sk,
       ss.ws_promo_sk,
       ss.ws_ext_sales_price,
       ss.ws_net_profit,
       p.p_promo_name,
       p.p_discount_active
   FROM sampled_sales ss
   FULL OUTER JOIN promotion p
       ON ss.ws_promo_sk = p.p_promo_sk
),
joined_all AS (
   SELECT
       fp.ws_order_number,
       fp.ws_item_sk,
       fp.ws_warehouse_sk,
       fp.ws_ext_sales_price,
       fp.ws_net_profit,
       fp.p_promo_name,
       fp.p_discount_active,
       w.w_warehouse_name,
       w.w_city,
       wr.wr_return_quantity,
       wr.wr_return_amt,
       wr.wr_net_loss
   FROM full_promo fp
   LEFT JOIN warehouse w
       ON fp.ws_warehouse_sk = w.w_warehouse_sk
   LEFT JOIN web_returns wr
       ON fp.ws_order_number = wr.wr_order_number
          AND fp.ws_item_sk = wr.wr_item_sk
   WHERE fp.p_discount_active = 'Y'
     AND w.w_state = 'CA'
     AND wr.wr_return_amt > 50
     AND wr.wr_return_quantity IS NOT NULL
     AND fp.ws_ext_sales_price > 200
),
anti_filtered AS (
   SELECT *
   FROM joined_all ja
   WHERE ja.ws_order_number NOT IN (
       SELECT ws_order_number
       FROM web_sales
       WHERE ws_ext_discount_amt > 300
   )
),
ranked AS (
   SELECT
       af.ws_order_number,
       af.ws_item_sk,
       af.ws_warehouse_sk,
       af.ws_ext_sales_price,
       af.ws_net_profit,
       af.p_promo_name,
       af.w_warehouse_name,
       af.w_city,
       af.wr_return_quantity,
       af.wr_return_amt,
       ROW_NUMBER() OVER (PARTITION BY af.ws_warehouse_sk ORDER BY af.ws_net_profit DESC) AS rn_warehouse_profit,
       RANK() OVER (ORDER BY af.ws_net_profit DESC) AS overall_rank
   FROM anti_filtered af
),
final_set AS (
   SELECT
       r.ws_order_number,
       r.ws_item_sk,
       r.ws_warehouse_sk,
       r.ws_ext_sales_price,
       r.ws_net_profit,
       r.p_promo_name,
       r.w_warehouse_name,
       r.w_city,
       r.wr_return_quantity,
       r.wr_return_amt,
       r.rn_warehouse_profit,
       r.overall_rank
   FROM ranked r
   WHERE r.rn_warehouse_profit <= 5
)
SELECT
   fs.ws_order_number,
   fs.ws_item_sk,
   fs.ws_warehouse_sk,
   fs.ws_ext_sales_price,
   fs.ws_net_profit,
   fs.p_promo_name,
   fs.w_warehouse_name,
   fs.w_city,
   fs.wr_return_quantity,
   fs.wr_return_amt,
   fs.rn_warehouse_profit,
   fs.overall_rank
FROM final_set fs
UNION DISTINCT
SELECT
   ws.ws_order_number,
   ws.ws_item_sk,
   ws.ws_warehouse_sk,
   ws.ws_ext_sales_price,
   ws.ws_net_profit,
   CAST(NULL AS varchar) AS p_promo_name,
   CAST(NULL AS varchar) AS w_warehouse_name,
   CAST(NULL AS varchar) AS w_city,
   CAST(NULL AS integer) AS wr_return_quantity,
   CAST(NULL AS decimal(7,2)) AS wr_return_amt,
   CAST(NULL AS integer) AS rn_warehouse_profit,
   CAST(NULL AS integer) AS overall_rank
FROM (
   SELECT ws_order_number, ws_item_sk, ws_warehouse_sk, ws_ext_sales_price, ws_net_profit
   FROM web_sales
   WHERE ws_quantity = 1
   EXCEPT
   SELECT wr.wr_order_number, ws_item_sk, ws_warehouse_sk, ws_ext_sales_price, ws_net_profit
   FROM web_returns wr
   JOIN web_sales ws ON ws.ws_order_number = wr.wr_order_number AND ws.ws_item_sk = wr.wr_item_sk
   WHERE wr.wr_return_quantity IS NOT NULL
) AS ws
ORDER BY ws_net_profit DESC, ws_order_number
LIMIT 100
