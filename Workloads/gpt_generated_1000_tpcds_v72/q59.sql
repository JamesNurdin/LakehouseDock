WITH
  item_cte AS (
    SELECT i_item_sk,
           i_item_id,
           i_category,
           i_brand_id,
           i_color,
           i_rec_start_date
    FROM   item
    WHERE  i_rec_start_date >= DATE '2000-01-01'
       AND i_brand_id IN (10005006, 3001002)
       AND i_color = 'steel'
  ),
  store_sales_agg AS (
    SELECT ss_item_sk,
           SUM(ss_net_paid)   AS store_sales_net,
           SUM(ss_quantity)   AS store_quantity
    FROM   store_sales
    GROUP BY ss_item_sk
  ),
  web_sales_agg AS (
    SELECT ws_item_sk,
           SUM(ws_net_paid)   AS web_sales_net,
           SUM(ws_quantity)   AS web_quantity
    FROM   web_sales
    GROUP BY ws_item_sk
  ),
  store_returns_agg AS (
    SELECT sr_item_sk,
           SUM(sr_return_amt_inc_tax) AS store_ret_amt,
           SUM(sr_return_quantity)    AS store_ret_qty
    FROM   store_returns
    GROUP BY sr_item_sk
  ),
  web_returns_agg AS (
    SELECT wr_item_sk,
           SUM(wr_return_amt_inc_tax) AS web_ret_amt,
           SUM(wr_return_quantity)    AS web_ret_qty
    FROM   web_returns
    GROUP BY wr_item_sk
  ),
  promo_agg AS (
    SELECT p_item_sk,
           SUM(p_cost) AS total_promo_cost
    FROM   promotion
    WHERE  p_discount_active = 'Y'
    GROUP BY p_item_sk
  ),
  catalog_info AS (
    SELECT cr.cr_item_sk,
           cc.cc_state,
           cp.cp_department,
           r.r_reason_desc
    FROM   catalog_returns cr
    JOIN   call_center cc   ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN   catalog_page cp   ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN   reason r         ON cr.cr_reason_sk      = r.r_reason_sk
    WHERE  cc.cc_state = 'CA'
      AND  r.r_reason_desc LIKE '%damage%'
  ),
  ss_dim AS (
    SELECT ss_item_sk,
           MIN(ss_addr_sk)   AS addr_sk,
           MIN(ss_cdemo_sk)  AS cdemo_sk,
           MIN(ss_hdemo_sk)  AS hdemo_sk
    FROM   store_sales
    GROUP BY ss_item_sk
  ),
  ws_dim AS (
    SELECT ws_item_sk,
           MIN(ws_web_page_sk) AS wp_sk,
           MIN(ws_web_site_sk) AS site_sk
    FROM   web_sales
    GROUP BY ws_item_sk
  )
SELECT
  i.i_item_id,
  i.i_category,
  i.i_brand_id,
  i.i_color,
  COALESCE(ss.store_sales_net, 0)    AS store_sales_net,
  COALESCE(ws.web_sales_net, 0)      AS web_sales_net,
  COALESCE(sr.store_ret_amt, 0)      AS store_returns_amt,
  COALESCE(wr.web_ret_amt, 0)        AS web_returns_amt,
  COALESCE(p.total_promo_cost, 0)    AS promo_cost,
  ca.ca_city,
  cd.cd_gender,
  hd.hd_buy_potential,
  wp.wp_type,
  wsite.web_state,
  ci.cc_state,
  ci.cp_department,
  ci.r_reason_desc,
  RANK() OVER (ORDER BY COALESCE(ss.store_sales_net,0) + COALESCE(ws.web_sales_net,0) DESC) AS sales_rank
FROM   item_cte i
LEFT JOIN store_sales_agg      ss   ON ss.ss_item_sk = i.i_item_sk
LEFT JOIN web_sales_agg        ws   ON ws.ws_item_sk = i.i_item_sk
LEFT JOIN store_returns_agg    sr   ON sr.sr_item_sk = i.i_item_sk
LEFT JOIN web_returns_agg      wr   ON wr.wr_item_sk = i.i_item_sk
LEFT JOIN promo_agg            p    ON p.p_item_sk = i.i_item_sk
LEFT JOIN catalog_info         ci   ON ci.cr_item_sk = i.i_item_sk
LEFT JOIN ss_dim               ssd  ON ssd.ss_item_sk = i.i_item_sk
LEFT JOIN customer_address     ca   ON ca.ca_address_sk = ssd.addr_sk
LEFT JOIN customer_demographics cd  ON cd.cd_demo_sk = ssd.cdemo_sk
LEFT JOIN household_demographics hd ON hd.hd_demo_sk = ssd.hdemo_sk
LEFT JOIN ws_dim               wsd  ON wsd.ws_item_sk = i.i_item_sk
LEFT JOIN web_page             wp   ON wp.wp_web_page_sk = wsd.wp_sk
LEFT JOIN web_site             wsite ON wsite.web_site_sk = wsd.site_sk
WHERE  cd.cd_gender = 'M'
  AND  hd.hd_buy_potential = '5000-9999'
  AND  wp.wp_type = 'content'
  AND  wsite.web_state = 'CA'
ORDER BY sales_rank
LIMIT 100
