WITH sales_agg AS (
   SELECT
       cs.cs_item_sk AS item_sk,
       i.i_brand,
       SUM(cs.cs_net_paid) AS total_net_paid,
       COUNT(*) AS sales_cnt,
       AVG(cs.cs_quantity) AS avg_qty,
       SUM(cs.cs_ext_discount_amt) AS total_discount
   FROM
       catalog_sales AS cs
       INNER JOIN item i ON cs.cs_item_sk = i.i_item_sk
       INNER JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
       INNER JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
       INNER JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
       INNER JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
       INNER JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
       INNER JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
   WHERE
       cs.cs_sold_date_sk BETWEEN 2451545 AND 2451910
       AND i.i_current_price > 100
       AND cd.cd_purchase_estimate >= 5000
       AND p.p_channel_email = 'N'
       AND cc.cc_state = 'CA'
   GROUP BY
       cs.cs_item_sk,
       i.i_brand
),

web_agg AS (
   SELECT
       ws.ws_item_sk AS item_sk,
       i2.i_brand,
       SUM(ws.ws_net_paid) AS total_net_paid,
       COUNT(*) AS sales_cnt,
       AVG(ws.ws_quantity) AS avg_qty,
       SUM(ws.ws_ext_discount_amt) AS total_discount
   FROM
       web_sales ws
       INNER JOIN item i2 ON ws.ws_item_sk = i2.i_item_sk
       INNER JOIN customer c2 ON ws.ws_bill_customer_sk = c2.c_customer_sk
       INNER JOIN customer_demographics cd2 ON ws.ws_bill_cdemo_sk = cd2.cd_demo_sk
       INNER JOIN household_demographics hd2 ON ws.ws_bill_hdemo_sk = hd2.hd_demo_sk
       INNER JOIN ship_mode sm2 ON ws.ws_ship_mode_sk = sm2.sm_ship_mode_sk
       INNER JOIN promotion p2 ON ws.ws_promo_sk = p2.p_promo_sk
   WHERE
       ws.ws_sold_date_sk BETWEEN 2451545 AND 2451910
       AND i2.i_current_price > 100
       AND cd2.cd_purchase_estimate >= 5000
       AND p2.p_channel_email = 'N'
       AND sm2.sm_type = 'AIR'
   GROUP BY
       ws.ws_item_sk,
       i2.i_brand
),

union_agg AS (
   SELECT item_sk, i_brand, total_net_paid, sales_cnt, avg_qty, total_discount
   FROM sales_agg
   UNION
   SELECT item_sk, i_brand, total_net_paid, sales_cnt, avg_qty, total_discount
   FROM web_agg
),

full_joined AS (
   SELECT
       u.item_sk,
       u.i_brand,
       u.total_net_paid,
       u.sales_cnt,
       u.avg_qty,
       u.total_discount,
       cr.cr_return_quantity,
       cr.cr_return_amount
   FROM
       union_agg u
       FULL OUTER JOIN catalog_returns cr
           ON u.item_sk = cr.cr_item_sk
),

sampled AS (
   SELECT *
   FROM full_joined
   TABLESAMPLE BERNOULLI (10)
)

SELECT
   item_sk,
   i_brand,
   SUM(total_net_paid) AS sum_net_paid,
   SUM(sales_cnt) AS total_sales,
   AVG(avg_qty) AS overall_avg_qty,
   SUM(total_discount) AS sum_discount,
   SUM(COALESCE(cr_return_quantity, 0)) AS total_return_qty,
   SUM(COALESCE(cr_return_amount, 0)) AS total_return_amount
FROM sampled
GROUP BY
   item_sk,
   i_brand
HAVING
   SUM(total_net_paid) > 10000
ORDER BY sum_net_paid DESC
OFFSET 20 ROWS
LIMIT 100
