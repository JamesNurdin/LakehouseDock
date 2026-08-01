WITH
  catalog_agg AS (
    SELECT
      cs.cs_order_number AS order_id,
      SUM(cs.cs_net_paid) AS total_net_paid,
      COUNT(*) AS line_cnt,
      CASE WHEN SUM(cs.cs_ext_discount_amt) > 1000 THEN 'HIGH' ELSE 'LOW' END AS discount_flag,
      ROW_NUMBER() OVER (ORDER BY SUM(cs.cs_net_paid) DESC) AS rn
    FROM catalog_sales cs
    JOIN customer c
      ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd
      ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
      ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN call_center cc
      ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp
      ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN warehouse w
      ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN promotion p
      ON cs.cs_promo_sk = p.p_promo_sk
    LEFT JOIN catalog_returns cr
      ON cr.cr_order_number = cs.cs_order_number
     AND cr.cr_item_sk = cs.cs_item_sk
    LEFT JOIN reason r
      ON cr.cr_reason_sk = r.r_reason_sk
    WHERE cc.cc_class = 'large'
      AND cp.cp_department = 'Books'
      AND p.p_discount_active = 'Y'
      AND cs.cs_sold_date_sk BETWEEN 2450815 AND 2451170
      AND cd.cd_gender = 'M'
      AND hd.hd_buy_potential = '500-1000'
    GROUP BY cs.cs_order_number
    HAVING SUM(cs.cs_net_paid) > 500
  ),
  store_agg AS (
    SELECT
      ss.ss_ticket_number AS order_id,
      SUM(ss.ss_net_paid) AS total_net_paid,
      COUNT(*) AS line_cnt,
      CASE WHEN SUM(ss.ss_ext_discount_amt) > 500 THEN 'HIGH' ELSE 'LOW' END AS discount_flag,
      ROW_NUMBER() OVER (ORDER BY SUM(ss.ss_net_paid) DESC) AS rn
    FROM store_sales ss
    FULL OUTER JOIN store s
      ON ss.ss_store_sk = s.s_store_sk
    JOIN customer c
      ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd
      ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
      ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN promotion p
      ON ss.ss_promo_sk = p.p_promo_sk
    WHERE s.s_store_name = 'Store 1'
      AND c.c_preferred_cust_flag = 'Y'
      AND cd.cd_marital_status = 'M'
      AND hd.hd_vehicle_count >= 2
      AND ss.ss_sold_date_sk BETWEEN 2450815 AND 2451170
    GROUP BY ss.ss_ticket_number
    HAVING SUM(ss.ss_net_paid) > 300
  ),
  web_agg AS (
    SELECT
      ws.ws_order_number AS order_id,
      SUM(ws.ws_net_paid) AS total_net_paid,
      COUNT(*) AS line_cnt,
      CASE WHEN SUM(ws.ws_ext_discount_amt) > 800 THEN 'HIGH' ELSE 'LOW' END AS discount_flag,
      ROW_NUMBER() OVER (ORDER BY SUM(ws.ws_net_paid) DESC) AS rn
    FROM web_sales ws
    JOIN customer c
      ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd
      ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
      ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN promotion p
      ON ws.ws_promo_sk = p.p_promo_sk
    JOIN warehouse w
      ON ws.ws_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN web_returns wr
      ON wr.wr_order_number = ws.ws_order_number
     AND wr.wr_item_sk = ws.ws_item_sk
    LEFT JOIN reason r
      ON wr.wr_reason_sk = r.r_reason_sk
    WHERE ws.ws_quantity > 0
      AND c.c_birth_year BETWEEN 1970 AND 1990
      AND cd.cd_education_status = 'College'
      AND hd.hd_income_band_sk = 5
      AND ws.ws_sold_date_sk BETWEEN 2450815 AND 2451170
    GROUP BY ws.ws_order_number
    HAVING SUM(ws.ws_net_paid) > 200
  ),
  union_orders AS (
    SELECT order_id FROM catalog_agg
    UNION
    SELECT order_id FROM web_agg
  ),
  intersect_orders AS (
    SELECT order_id FROM catalog_agg
    INTERSECT
    SELECT order_id FROM store_agg
  ),
  final_set AS (
    SELECT
      u.order_id,
      ca.total_net_paid AS catalog_net,
      sa.total_net_paid AS store_net,
      wa.total_net_paid AS web_net,
      CASE
        WHEN ca.total_net_paid IS NULL THEN 'STORE_OR_WEB_ONLY'
        WHEN sa.total_net_paid IS NULL THEN 'CATALOG_OR_WEB_ONLY'
        WHEN wa.total_net_paid IS NULL THEN 'CATALOG_OR_STORE_ONLY'
        ELSE 'ALL_CHANNELS'
      END AS presence_flag,
      ROW_NUMBER() OVER (PARTITION BY u.order_id ORDER BY u.order_id) AS global_rn,
      SUM(COALESCE(ca.total_net_paid,0) + COALESCE(sa.total_net_paid,0) + COALESCE(wa.total_net_paid,0))
        OVER (PARTITION BY CASE
                      WHEN ca.total_net_paid IS NOT NULL THEN 'CAT'
                      WHEN sa.total_net_paid IS NOT NULL THEN 'STORE'
                      ELSE 'WEB'
                    END) AS partition_sum
    FROM union_orders u
    LEFT JOIN catalog_agg ca ON u.order_id = ca.order_id
    LEFT JOIN store_agg sa ON u.order_id = sa.order_id
    LEFT JOIN web_agg wa ON u.order_id = wa.order_id
    WHERE NOT EXISTS (
          SELECT 1 FROM catalog_returns cr
          WHERE cr.cr_order_number = u.order_id
            AND cr.cr_reason_sk = (
                  SELECT r_reason_sk FROM reason WHERE r_reason_desc = 'Customer not satisfied'
                )
        )
      AND u.order_id IN (SELECT order_id FROM intersect_orders)
  )
SELECT *
FROM final_set
ORDER BY global_rn
LIMIT 100
