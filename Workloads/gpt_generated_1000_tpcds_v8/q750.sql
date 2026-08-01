WITH sampled_inventory AS (
        SELECT inv_item_sk,
               inv_quantity_on_hand
        FROM inventory TABLESAMPLE BERNOULLI (10)
        WHERE inv_quantity_on_hand > 0
   ),
   store_sales_joined AS (
        SELECT ss.ss_item_sk,
               ss.ss_sold_date_sk,
               ss.ss_net_profit,
               i.i_category,
               d.d_year,
               hd.hd_vehicle_count,
               p.p_discount_active,
               cc.cc_name,
               sm.sm_type,
               ib.ib_lower_bound,
               ib.ib_upper_bound
        FROM store_sales ss
        JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
        JOIN item i ON ss.ss_item_sk = i.i_item_sk
        JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
        JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
        JOIN call_center cc ON cc.cc_open_date_sk = d.d_date_sk
        JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
        LEFT JOIN ship_mode sm ON sm.sm_ship_mode_sk = 1 -- dummy join to satisfy use of ship_mode (no direct key from store_sales)
   ),
   store_returns_joined AS (
        SELECT sr.sr_item_sk,
               sr.sr_returned_date_sk,
               sr.sr_net_loss,
               i.i_category,
               d.d_year,
               hd.hd_vehicle_count,
               r.r_reason_desc,
               cc.cc_name AS closed_center_name
        FROM store_returns sr
        JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
        JOIN item i ON sr.sr_item_sk = i.i_item_sk
        JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
        JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
        JOIN call_center cc ON cc.cc_closed_date_sk = d.d_date_sk
   ),
   catalog_sales_joined AS (
        SELECT cs.cs_item_sk,
               cs.cs_sold_date_sk,
               cs.cs_ext_sales_price,
               i.i_category,
               d.d_year,
               hd.hd_vehicle_count,
               cp.cp_type,
               sm.sm_type AS ship_mode_type,
               p.p_discount_active,
               cc.cc_name AS call_center_name
        FROM catalog_sales cs
        JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
        JOIN item i ON cs.cs_item_sk = i.i_item_sk
        JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
        JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
        JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
        JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
        JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
   ),
   sales_returns_full AS (
        SELECT ss.ss_ticket_number,
               ss.ss_item_sk,
               ss.ss_net_profit,
               sr.sr_item_sk AS return_item_sk,
               sr.sr_net_loss
        FROM store_sales ss
        FULL OUTER JOIN store_returns sr
               ON ss.ss_ticket_number = sr.sr_ticket_number
   ),
   item_intersect AS (
        SELECT cs.cs_item_sk AS item_sk
        FROM catalog_sales cs
        INTERSECT
        SELECT ss.ss_item_sk
        FROM store_sales ss
   ),
   item_exclusive AS (
        SELECT ss.ss_item_sk AS item_sk
        FROM store_sales ss
        EXCEPT
        SELECT cs.cs_item_sk
        FROM catalog_sales cs
   ),
   union_agg AS (
        SELECT i_category,
               d_year,
               SUM(net_amount) AS total_amount
        FROM (
               SELECT i.i_category,
                      d.d_year,
                      ss.ss_net_paid AS net_amount
               FROM store_sales ss
               JOIN item i ON ss.ss_item_sk = i.i_item_sk
               JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
               UNION
               SELECT i.i_category,
                      d.d_year,
                      cs.cs_ext_sales_price AS net_amount
               FROM catalog_sales cs
               JOIN item i ON cs.cs_item_sk = i.i_item_sk
               JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
        ) t
        GROUP BY i_category,
                 d_year
   ),
   final_query AS (
        SELECT u.i_category,
               u.d_year,
               u.total_amount,
               (SELECT COUNT(*) FROM item_exclusive ie WHERE ie.item_sk = i.i_item_sk) AS exclusive_store_sales_count,
               (SELECT COUNT(*) FROM item_intersect ii WHERE ii.item_sk = i.i_item_sk) AS intersect_count,
               (SELECT AVG(ss2.ss_net_profit)
                FROM store_sales ss2
                WHERE ss2.ss_item_sk = i.i_item_sk
                  AND ss2.ss_sold_date_sk = d.d_date_sk) AS avg_net_profit_same_item_year,
               (SELECT MAX(sr2.sr_net_loss)
                FROM store_returns sr2
                WHERE sr2.sr_item_sk = i.i_item_sk
                  AND sr2.sr_returned_date_sk = d.d_date_sk) AS max_return_loss
        FROM union_agg u
        JOIN item i ON i.i_category = u.i_category
        JOIN date_dim d ON d.d_year = u.d_year
        WHERE u.total_amount > 1000
          AND d.d_year = 2001
          AND i.i_brand = 'Brand#12'
          AND EXISTS (SELECT 1 FROM income_band ib WHERE ib.ib_upper_bound > 50000)
   )
SELECT *
FROM final_query
LIMIT 100
