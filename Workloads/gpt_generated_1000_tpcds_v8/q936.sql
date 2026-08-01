WITH sampled_inventory AS (
    SELECT inv_date_sk, inv_item_sk, inv_quantity_on_hand
    FROM inventory TABLESAMPLE BERNOULLI (10)
),
item_latest_promo AS (
    SELECT i.i_item_sk,
           i.i_brand_id,
           i.i_class_id,
           i.i_current_price,
           p.p_promo_sk,
           p.p_discount_active,
           p.p_start_date_sk
    FROM item i
    LEFT JOIN LATERAL (
        SELECT p_inner.p_promo_sk, p_inner.p_discount_active, p_inner.p_start_date_sk
        FROM promotion p_inner
        WHERE p_inner.p_item_sk = i.i_item_sk
        ORDER BY p_inner.p_start_date_sk DESC
        LIMIT 1
    ) p ON TRUE
),
store_agg AS (
    SELECT
        d.d_year,
        i.i_item_sk,
        i.i_brand_id,
        i.i_class_id,
        c.c_customer_sk,
        hd.hd_vehicle_count,
        ca.ca_state,
        p.p_discount_active,
        SUM(ss.ss_net_paid) AS total_net_paid,
        COUNT(*) AS txn_cnt
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    GROUP BY d.d_year, i.i_item_sk, i.i_brand_id, i.i_class_id, c.c_customer_sk, hd.hd_vehicle_count, ca.ca_state, p.p_discount_active
),
web_agg AS (
    SELECT
        d.d_year,
        i.i_item_sk,
        i.i_brand_id,
        i.i_class_id,
        c.c_customer_sk,
        hd.hd_vehicle_count,
        ca.ca_state,
        p.p_discount_active,
        SUM(ws.ws_net_paid) AS total_net_paid,
        COUNT(*) AS txn_cnt
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    GROUP BY d.d_year, i.i_item_sk, i.i_brand_id, i.i_class_id, c.c_customer_sk, hd.hd_vehicle_count, ca.ca_state, p.p_discount_active
),
catalog_agg AS (
    SELECT
        d.d_year,
        i.i_item_sk,
        i.i_brand_id,
        i.i_class_id,
        c.c_customer_sk,
        hd.hd_vehicle_count,
        ca.ca_state,
        p.p_discount_active,
        SUM(cs.cs_net_paid) AS total_net_paid,
        COUNT(*) AS txn_cnt
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    GROUP BY d.d_year, i.i_item_sk, i.i_brand_id, i.i_class_id, c.c_customer_sk, hd.hd_vehicle_count, ca.ca_state, p.p_discount_active
),
combined_sw AS (
    SELECT
        COALESCE(s.d_year, w.d_year) AS year,
        COALESCE(s.i_item_sk, w.i_item_sk) AS item_sk,
        COALESCE(s.i_brand_id, w.i_brand_id) AS brand_id,
        COALESCE(s.i_class_id, w.i_class_id) AS class_id,
        COALESCE(s.c_customer_sk, w.c_customer_sk) AS customer_sk,
        COALESCE(s.hd_vehicle_count, w.hd_vehicle_count) AS vehicle_count,
        COALESCE(s.ca_state, w.ca_state) AS state,
        COALESCE(s.p_discount_active, w.p_discount_active) AS discount_active,
        COALESCE(s.total_net_paid, 0) + COALESCE(w.total_net_paid, 0) AS total_net_paid,
        COALESCE(s.txn_cnt, 0) + COALESCE(w.txn_cnt, 0) AS txn_cnt
    FROM store_agg s
    FULL OUTER JOIN web_agg w
      ON s.d_year = w.d_year
     AND s.i_item_sk = w.i_item_sk
),
combined_all AS (
    SELECT
        COALESCE(sw.year, ca.d_year) AS year,
        COALESCE(sw.item_sk, ca.i_item_sk) AS item_sk,
        COALESCE(sw.brand_id, ca.i_brand_id) AS brand_id,
        COALESCE(sw.class_id, ca.i_class_id) AS class_id,
        COALESCE(sw.customer_sk, ca.c_customer_sk) AS customer_sk,
        COALESCE(sw.vehicle_count, ca.hd_vehicle_count) AS vehicle_count,
        COALESCE(sw.state, ca.ca_state) AS state,
        COALESCE(sw.discount_active, ca.p_discount_active) AS discount_active,
        COALESCE(sw.total_net_paid, 0) + COALESCE(ca.total_net_paid, 0) AS total_net_paid,
        COALESCE(sw.txn_cnt, 0) + COALESCE(ca.txn_cnt, 0) AS txn_cnt
    FROM combined_sw sw
    FULL OUTER JOIN catalog_agg ca
      ON sw.year = ca.d_year
     AND sw.item_sk = ca.i_item_sk
)
SELECT
    caa.year,
    caa.brand_id,
    caa.class_id,
    caa.state,
    caa.total_net_paid,
    caa.txn_cnt,
    AVG(caa.total_net_paid) OVER (PARTITION BY caa.year) AS avg_net_paid_year,
    (SELECT COUNT(*)
     FROM (SELECT cs_order_number FROM catalog_sales) EXCEPT
          SELECT cr_order_number FROM catalog_returns) AS orders_not_returned,
    (SELECT COUNT(*)
     FROM (SELECT ss_item_sk FROM store_sales) INTERSECT
          SELECT ws_item_sk FROM web_sales) AS items_sold_both_channels
FROM combined_all caa
WHERE caa.year = 2002
  AND caa.brand_id = 10005006
  AND caa.vehicle_count >= 1
  AND caa.discount_active = 'Y'
  AND EXISTS (
        SELECT 1
        FROM sampled_inventory inv
        JOIN item i2 ON inv.inv_item_sk = i2.i_item_sk
        WHERE i2.i_item_sk = caa.item_sk
          AND inv.inv_quantity_on_hand > 0
    )
ORDER BY caa.year DESC, caa.total_net_paid DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
