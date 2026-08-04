WITH
  sampled_inventory AS (
    SELECT inv_item_sk, inv_quantity_on_hand
    FROM inventory
    TABLESAMPLE BERNOULLI (10)
    WHERE inv_quantity_on_hand > 500
  ),
  intersect_items AS (
    SELECT inv_item_sk
    FROM sampled_inventory
    INTERSECT
    SELECT ws_item_sk
    FROM web_sales
  ),
  base_items AS (
    SELECT i.i_item_sk,
           i.i_product_name,
           i.i_category,
           i.i_brand,
           i.i_current_price
    FROM item i
    JOIN intersect_items ii ON i.i_item_sk = ii.inv_item_sk
  ),
  catalog_data AS (
    SELECT cr.cr_returned_date_sk,
           cr.cr_returned_time_sk,
           cr.cr_item_sk,
           cr.cr_return_amount,
           cr.cr_net_loss,
           cc.cc_name,
           c.c_customer_id,
           ca.ca_city,
           cd.cd_gender,
           hd.hd_income_band_sk,
           td.t_hour
    FROM catalog_returns cr
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN customer c ON cr.cr_returning_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON cr.cr_returning_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON cr.cr_returning_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON cr.cr_returning_hdemo_sk = hd.hd_demo_sk
    JOIN time_dim td ON cr.cr_returned_time_sk = td.t_time_sk
    WHERE cr.cr_return_amount > 100
  ),
  store_data AS (
    SELECT sr.sr_returned_date_sk,
           sr.sr_return_time_sk,
           sr.sr_item_sk,
           sr.sr_return_amt,
           sr.sr_net_loss,
           s.s_store_name,
           c.c_customer_id AS store_customer_id,
           ca.ca_state,
           cd.cd_marital_status,
           hd.hd_vehicle_count,
           td.t_hour
    FROM store_returns sr
    FULL OUTER JOIN store s ON sr.sr_store_sk = s.s_store_sk
    LEFT JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    LEFT JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    LEFT JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN time_dim td ON sr.sr_return_time_sk = td.t_time_sk
    WHERE sr.sr_return_amt IS NOT NULL
  ),
  web_data AS (
    SELECT wr.wr_returned_date_sk,
           wr.wr_returned_time_sk,
           wr.wr_item_sk,
           wr.wr_return_amt,
           wr.wr_net_loss,
           ws.ws_order_number,
           ws.ws_sales_price,
           c.c_customer_id AS web_customer_id,
           ca.ca_country,
           cd.cd_education_status,
           hd.hd_buy_potential,
           td.t_hour
    FROM web_returns wr
    JOIN web_sales ws ON wr.wr_order_number = ws.ws_order_number
    JOIN customer c ON wr.wr_returning_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON wr.wr_returning_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON wr.wr_returning_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON wr.wr_returning_hdemo_sk = hd.hd_demo_sk
    JOIN time_dim td ON wr.wr_returned_time_sk = td.t_time_sk
    WHERE ws.ws_sales_price > 50
  )
SELECT final.*
FROM (
  SELECT i.i_item_sk,
         i.i_product_name,
         i.i_category,
         i.i_brand,
         i.i_current_price,
         COALESCE(cd.cr_net_loss, 0) + COALESCE(sd.sr_net_loss, 0) + COALESCE(wd.wr_net_loss, 0) AS total_net_loss,
         (
           SELECT SUM(inv_quantity_on_hand)
           FROM inventory inv
           WHERE inv.inv_item_sk = i.i_item_sk
         ) AS total_inventory_qty,
         ROW_NUMBER() OVER (
           PARTITION BY i.i_category
           ORDER BY COALESCE(cd.cr_net_loss, 0) + COALESCE(sd.sr_net_loss, 0) + COALESCE(wd.wr_net_loss, 0) DESC
         ) AS rn
  FROM base_items i
  LEFT JOIN catalog_data cd ON i.i_item_sk = cd.cr_item_sk
  LEFT JOIN store_data sd ON i.i_item_sk = sd.sr_item_sk
  LEFT JOIN web_data wd ON i.i_item_sk = wd.wr_item_sk
  WHERE i.i_current_price BETWEEN 10 AND 1000
    AND i.i_brand IN ('Brand#12', 'Brand#23')
) final
WHERE final.rn <= 5
ORDER BY final.i_category, final.rn
LIMIT 100
