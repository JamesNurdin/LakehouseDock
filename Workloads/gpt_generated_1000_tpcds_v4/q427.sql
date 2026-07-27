WITH
  catalog_agg AS (
    SELECT
      cs.cs_item_sk,
      d.d_year,
      SUM(cs.cs_net_profit) AS catalog_profit
    FROM catalog_sales cs
    JOIN date_dim d
      ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN promotion p
      ON cs.cs_promo_sk = p.p_promo_sk
    JOIN call_center cc
      ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN warehouse w
      ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN customer c
      ON cs.cs_bill_customer_sk = c.c_customer_sk
    WHERE p.p_channel_demo = 'N'
      AND d.d_year BETWEEN 1999 AND 2001
      AND c.c_preferred_cust_flag = 'Y'
    GROUP BY cs.cs_item_sk, d.d_year
  ),
  web_agg AS (
    SELECT
      ws.ws_item_sk,
      d.d_year,
      SUM(ws.ws_net_profit) AS web_profit
    FROM web_sales ws
    JOIN date_dim d
      ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN promotion p
      ON ws.ws_promo_sk = p.p_promo_sk
    JOIN warehouse w
      ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN customer c
      ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE p.p_channel_demo = 'N'
      AND d.d_year BETWEEN 1999 AND 2001
      AND c.c_preferred_cust_flag = 'Y'
    GROUP BY ws.ws_item_sk, d.d_year
  ),
  returns_agg AS (
    SELECT
      sr.sr_item_sk,
      d.d_year,
      SUM(sr.sr_net_loss) AS return_loss
    FROM store_returns sr
    JOIN date_dim d
      ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN store s
      ON sr.sr_store_sk = s.s_store_sk
    JOIN date_dim d_store
      ON s.s_closed_date_sk = d_store.d_date_sk
    WHERE s.s_state = 'CA'
      AND d.d_year BETWEEN 1999 AND 2001
    GROUP BY sr.sr_item_sk, d.d_year
  ),
  item_sales AS (
    SELECT
      i.i_item_id,
      i.i_product_name,
      ca.d_year,
      ca.catalog_profit,
      wa.web_profit,
      ra.return_loss
    FROM item i
    LEFT JOIN catalog_agg ca
      ON i.i_item_sk = ca.cs_item_sk
    LEFT JOIN web_agg wa
      ON i.i_item_sk = wa.ws_item_sk
         AND ca.d_year = wa.d_year
    LEFT JOIN returns_agg ra
      ON i.i_item_sk = ra.sr_item_sk
         AND ca.d_year = ra.d_year
    WHERE i.i_manager_id IN (44, 64)
  )
SELECT
  d_year,
  i_item_id,
  i_product_name,
  (COALESCE(catalog_profit, 0) + COALESCE(web_profit, 0)) AS total_profit,
  COALESCE(return_loss, 0)                     AS total_return_loss,
  (COALESCE(catalog_profit, 0) + COALESCE(web_profit, 0) - COALESCE(return_loss, 0)) AS net_contribution,
  RANK() OVER (PARTITION BY d_year ORDER BY (COALESCE(catalog_profit, 0) + COALESCE(web_profit, 0) - COALESCE(return_loss, 0)) DESC) AS profit_rank
FROM item_sales
GROUP BY
  d_year,
  i_item_id,
  i_product_name,
  catalog_profit,
  web_profit,
  return_loss
HAVING (COALESCE(catalog_profit, 0) + COALESCE(web_profit, 0) - COALESCE(return_loss, 0)) > 5000
ORDER BY d_year, profit_rank
