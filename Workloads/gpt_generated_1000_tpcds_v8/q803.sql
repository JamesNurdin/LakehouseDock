WITH
  inventory_agg AS (
    SELECT
      inv_item_sk,
      inv_warehouse_sk,
      SUM(inv_quantity_on_hand) AS total_qty_on_hand
    FROM inventory TABLESAMPLE BERNOULLI (10)
    GROUP BY inv_item_sk, inv_warehouse_sk
  ),
  sales_agg AS (
    SELECT
      cs_item_sk   AS item_sk,
      cs_warehouse_sk AS warehouse_sk,
      SUM(cs_net_paid)   AS net_paid,
      SUM(cs_net_profit) AS profit,
      COUNT(*)           AS sales_cnt
    FROM catalog_sales
    WHERE cs_sold_date_sk BETWEEN 2450000 AND 2452000
      AND cs_coupon_amt > 10
      AND cs_ext_discount_amt < 500
      AND cs_list_price >= 100
      AND cs_quantity >= 1
    GROUP BY cs_item_sk, cs_warehouse_sk
  ),
  web_sales_agg AS (
    SELECT
      ws_item_sk   AS item_sk,
      ws_warehouse_sk AS warehouse_sk,
      SUM(ws_net_paid)   AS net_paid,
      SUM(ws_net_profit) AS profit,
      COUNT(*)           AS sales_cnt
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 2450000 AND 2452000
      AND ws_coupon_amt > 5
      AND ws_ext_discount_amt < 300
      AND ws_list_price >= 50
      AND ws_quantity >= 1
    GROUP BY ws_item_sk, ws_warehouse_sk
  ),
  union_sales AS (
    SELECT item_sk, warehouse_sk, net_paid, profit, sales_cnt
    FROM sales_agg
    UNION DISTINCT
    SELECT item_sk, warehouse_sk, net_paid, profit, sales_cnt
    FROM web_sales_agg
  ),
  intersect_items AS (
    SELECT item_sk FROM sales_agg
    INTERSECT
    SELECT item_sk FROM web_sales_agg
  )
SELECT
  sub.i_item_id,
  sub.i_product_name,
  sub.w_warehouse_name,
  sub.total_qty_on_hand,
  sub.net_paid,
  sub.profit,
  sub.sales_cnt,
  sub.distinct_orders,
  sub.r_reason_desc,
  sub.s_store_name,
  sub.wp_url,
  sub.web_name,
  sub.c_first_name,
  sub.cd_gender,
  sub.p_promo_name,
  sub.coupon_array_sum,
  CASE WHEN sub.profit > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_flag
FROM (
  SELECT
    i.i_item_id,
    i.i_product_name,
    w.w_warehouse_name,
    inv.total_qty_on_hand,
    us.net_paid,
    us.profit,
    us.sales_cnt,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
    r.r_reason_desc,
    s.s_store_name,
    wp.wp_url,
    ws_site.web_name,
    c.c_first_name,
    cd.cd_gender,
    p.p_promo_name,
    cn.cnt AS coupon_array_sum
  FROM union_sales us
  JOIN item i ON i.i_item_sk = us.item_sk
  JOIN warehouse w ON w.w_warehouse_sk = us.warehouse_sk
  LEFT JOIN inventory_agg inv ON inv.inv_item_sk = i.i_item_sk AND inv.inv_warehouse_sk = w.w_warehouse_sk
  LEFT JOIN catalog_sales cs ON cs.cs_item_sk = i.i_item_sk AND cs.cs_warehouse_sk = w.w_warehouse_sk
  LEFT JOIN web_sales wsale ON wsale.ws_item_sk = i.i_item_sk AND wsale.ws_warehouse_sk = w.w_warehouse_sk
  LEFT JOIN promotion p ON p.p_promo_sk = cs.cs_promo_sk OR p.p_promo_sk = wsale.ws_promo_sk
  LEFT JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk
  LEFT JOIN store s ON s.s_store_sk = sr.sr_store_sk
  LEFT JOIN reason r ON r.r_reason_sk = sr.sr_reason_sk
  LEFT JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk
  LEFT JOIN web_page wp ON wp.wp_web_page_sk = wr.wr_web_page_sk
  LEFT JOIN web_site ws_site ON ws_site.web_site_sk = wsale.ws_web_site_sk
  LEFT JOIN customer c ON c.c_customer_sk = cs.cs_bill_customer_sk
  LEFT JOIN customer_demographics cd ON cd.cd_demo_sk = c.c_current_cdemo_sk
  LEFT JOIN LATERAL (
    SELECT SUM(val) AS cnt
    FROM UNNEST(ARRAY[cs.cs_coupon_amt, cs.cs_ext_discount_amt]) AS t(val)
  ) AS cn ON TRUE
  WHERE us.item_sk IN (SELECT item_sk FROM intersect_items)
    AND i.i_current_price > 10
    AND w.w_gmt_offset BETWEEN -5 AND 5
    AND s.s_state = 'CA'
    AND r.r_reason_desc LIKE '%price%'
    AND c.c_birth_year BETWEEN 1950 AND 1990
  GROUP BY
    i.i_item_id,
    i.i_product_name,
    w.w_warehouse_name,
    inv.total_qty_on_hand,
    us.net_paid,
    us.profit,
    us.sales_cnt,
    r.r_reason_desc,
    s.s_store_name,
    wp.wp_url,
    ws_site.web_name,
    c.c_first_name,
    cd.cd_gender,
    p.p_promo_name,
    cn.cnt
) sub
ORDER BY sub.profit DESC
LIMIT 100
