WITH base AS (
   SELECT
      cc.cc_state,
      i.i_category,
      p.p_cost,
      cs.cs_order_number,
      cs.cs_net_paid,
      cs.cs_sales_price,
      cs.cs_quantity,
      cs.cs_net_profit,
      cr.cr_return_amount,
      cr.cr_return_tax,
      cr.cr_return_quantity,
      wr.wr_return_amt,
      wr.wr_return_quantity,
      wr.wr_refunded_cash
   FROM tpcds.call_center cc
   JOIN tpcds.catalog_sales cs
     ON cs.cs_call_center_sk = cc.cc_call_center_sk
   JOIN tpcds.item i
     ON cs.cs_item_sk = i.i_item_sk
   JOIN tpcds.promotion p
     ON cs.cs_promo_sk = p.p_promo_sk
        AND p.p_item_sk = i.i_item_sk
   JOIN tpcds.catalog_returns cr
     ON cr.cr_item_sk = i.i_item_sk
        AND cr.cr_call_center_sk = cc.cc_call_center_sk
        AND cr.cr_order_number = cs.cs_order_number
   JOIN tpcds.web_returns wr
     ON wr.wr_item_sk = i.i_item_sk
   WHERE cc.cc_state = 'CA'
     AND i.i_brand_id = 7
     AND p.p_discount_active = 'Y'
)
SELECT
   cc_state,
   i_category,
   source,
   total_net_paid,
   total_net_profit,
   total_return_amount,
   total_web_return_amount,
   num_orders,
   avg_sales_price,
   min_promo_cost,
   max_promo_cost,
   high_tax_return_sum,
   profit_level
FROM (
   SELECT
      cc_state,
      i_category,
      'Catalog' AS source,
      SUM(cs_net_paid) AS total_net_paid,
      SUM(cs_net_profit) AS total_net_profit,
      SUM(cr_return_amount) AS total_return_amount,
      SUM(wr_return_amt) AS total_web_return_amount,
      COUNT(DISTINCT cs_order_number) AS num_orders,
      AVG(cs_sales_price) AS avg_sales_price,
      MIN(p_cost) AS min_promo_cost,
      MAX(p_cost) AS max_promo_cost,
      SUM(CASE WHEN cr_return_tax > 20 THEN cr_return_tax ELSE 0 END) AS high_tax_return_sum,
      CASE WHEN SUM(cs_net_profit) > 10000 THEN 'High' ELSE 'Low' END AS profit_level
   FROM base
   WHERE cr_return_quantity > 1
   GROUP BY GROUPING SETS ((cc_state, i_category), (cc_state), (i_category), ())
   UNION
   SELECT
      cc_state,
      i_category,
      'Web' AS source,
      SUM(cs_net_paid) AS total_net_paid,
      SUM(cs_net_profit) AS total_net_profit,
      SUM(cr_return_amount) AS total_return_amount,
      SUM(wr_return_amt) AS total_web_return_amount,
      COUNT(DISTINCT cs_order_number) AS num_orders,
      AVG(cs_sales_price) AS avg_sales_price,
      MIN(p_cost) AS min_promo_cost,
      MAX(p_cost) AS max_promo_cost,
      SUM(CASE WHEN cr_return_tax > 20 THEN cr_return_tax ELSE 0 END) AS high_tax_return_sum,
      CASE WHEN SUM(cs_net_profit) > 10000 THEN 'High' ELSE 'Low' END AS profit_level
   FROM base
   WHERE wr_refunded_cash > 500
   GROUP BY GROUPING SETS ((cc_state, i_category), (cc_state), (i_category), ())
) AS combined
ORDER BY cc_state, i_category, source, profit_level DESC
LIMIT 100
