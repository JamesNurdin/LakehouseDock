WITH
  ws_agg AS (
    SELECT
      s.s_store_id,
      i.i_brand,
      d.d_year,
      SUM(ws.ws_net_profit) AS total_net_profit,
      SUM(ws.ws_quantity) AS total_quantity,
      COUNT(DISTINCT ws.ws_order_number) AS order_cnt
    FROM web_sales ws
    JOIN date_dim d               ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i                   ON ws.ws_item_sk = i.i_item_sk
    JOIN store s                  ON s.s_closed_date_sk = d.d_date_sk
    JOIN promotion p              ON ws.ws_promo_sk = p.p_promo_sk
                                 AND p.p_item_sk = i.i_item_sk
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca      ON ws.ws_bill_addr_sk = ca.ca_address_sk
    WHERE d.d_year = 2000
      AND s.s_state = 'CA'
      AND i.i_brand = 'Brand#12'
      AND p.p_discount_active = 'Y'
      AND s.s_rec_end_date >= DATE '2000-01-01'
    GROUP BY s.s_store_id, i.i_brand, d.d_year
  ),
  cr_agg AS (
    SELECT
      s.s_store_id,
      i.i_brand,
      d.d_year,
      SUM(cr.cr_return_amount) AS total_catalog_return_amount,
      COUNT(*) AS catalog_return_cnt
    FROM catalog_returns cr
    JOIN date_dim d               ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i                   ON cr.cr_item_sk = i.i_item_sk
    JOIN store s                  ON s.s_closed_date_sk = d.d_date_sk
    JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca      ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    WHERE d.d_year = 2000
      AND s.s_state = 'CA'
    GROUP BY s.s_store_id, i.i_brand, d.d_year
  ),
  wr_agg AS (
    SELECT
      s.s_store_id,
      i.i_brand,
      d.d_year,
      SUM(wr.wr_return_amt) AS total_web_return_amount,
      COUNT(*) AS web_return_cnt
    FROM web_returns wr
    JOIN date_dim d               ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN item i                   ON wr.wr_item_sk = i.i_item_sk
    JOIN store s                  ON s.s_closed_date_sk = d.d_date_sk
    JOIN customer_demographics cd ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca      ON wr.wr_refunded_addr_sk = ca.ca_address_sk
    WHERE d.d_year = 2000
      AND s.s_state = 'CA'
    GROUP BY s.s_store_id, i.i_brand, d.d_year
  ),
  inv_agg AS (
    SELECT
      s.s_store_id,
      i.i_brand,
      d.d_year,
      SUM(inv.inv_quantity_on_hand) AS total_inventory
    FROM inventory inv
    JOIN date_dim d ON inv.inv_date_sk = d.d_date_sk
    JOIN item i    ON inv.inv_item_sk = i.i_item_sk
    JOIN store s   ON s.s_closed_date_sk = d.d_date_sk
    WHERE d.d_year = 2000
      AND s.s_state = 'CA'
    GROUP BY s.s_store_id, i.i_brand, d.d_year
  )
SELECT
  ws.s_store_id,
  ws.i_brand,
  ws.d_year,
  ws.total_net_profit,
  inv.total_inventory,
  cr.total_catalog_return_amount,
  cr.catalog_return_cnt,
  wr.total_web_return_amount,
  wr.web_return_cnt,
  ws.order_cnt,
  RANK() OVER (PARTITION BY ws.d_year ORDER BY ws.total_net_profit DESC) AS profit_rank
FROM ws_agg ws
LEFT JOIN cr_agg cr   ON ws.s_store_id = cr.s_store_id
                     AND ws.i_brand   = cr.i_brand
                     AND ws.d_year    = cr.d_year
LEFT JOIN wr_agg wr   ON ws.s_store_id = wr.s_store_id
                     AND ws.i_brand   = wr.i_brand
                     AND ws.d_year    = wr.d_year
LEFT JOIN inv_agg inv ON ws.s_store_id = inv.s_store_id
                     AND ws.i_brand   = inv.i_brand
                     AND ws.d_year    = inv.d_year
ORDER BY ws.d_year, profit_rank
LIMIT 100
