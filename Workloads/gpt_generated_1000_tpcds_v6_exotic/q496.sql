WITH cs_agg AS (
        SELECT cs_bill_customer_sk AS customer_sk,
               SUM(cs_net_paid)          AS total_cs_net_paid,
               COUNT(*)                 AS cnt_cs_sales
        FROM   catalog_sales
        WHERE  cs_sold_date_sk BETWEEN 2450816 AND 2451152
        GROUP BY cs_bill_customer_sk
      ),
      ws_agg AS (
        SELECT ws_bill_customer_sk AS customer_sk,
               SUM(ws_net_paid)          AS total_ws_net_paid,
               COUNT(*)                 AS cnt_ws_sales
        FROM   web_sales
        WHERE  ws_sold_date_sk BETWEEN 2450816 AND 2451152
        GROUP BY ws_bill_customer_sk
      )
SELECT
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        hd.hd_buy_potential,
        hd.hd_vehicle_count,
        cc.cc_name,
        cp.cp_department,
        p.p_promo_name,
        sm_cs.sm_type               AS cs_ship_mode_type,
        sm_ws.sm_type               AS ws_ship_mode_type,
        cs_agg.total_cs_net_paid,
        ws_agg.total_ws_net_paid,
        RANK() OVER (PARTITION BY hd.hd_buy_potential
                     ORDER BY (cs_agg.total_cs_net_paid + ws_agg.total_ws_net_paid) DESC) AS purchase_rank,
        (
            SELECT MAX(cs2.cs_ext_sales_price)
            FROM   catalog_sales cs2
            WHERE  cs2.cs_promo_sk = p.p_promo_sk
        ) AS max_catalog_sale_price
FROM   customer c
JOIN   household_demographics hd      ON c.c_current_hdemo_sk = hd.hd_demo_sk
JOIN   store_returns sr             ON sr.sr_customer_sk = c.c_customer_sk
JOIN   reason r                     ON sr.sr_reason_sk = r.r_reason_sk
JOIN   cs_agg ON cs_agg.customer_sk = c.c_customer_sk
JOIN   catalog_sales cs             ON cs.cs_bill_customer_sk = c.c_customer_sk
JOIN   call_center cc               ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN   catalog_page cp              ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN   promotion p                  ON cs.cs_promo_sk = p.p_promo_sk
JOIN   ship_mode sm_cs              ON cs.cs_ship_mode_sk = sm_cs.sm_ship_mode_sk
JOIN   web_sales ws                ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN   ws_agg ON ws_agg.customer_sk = c.c_customer_sk
JOIN   ship_mode sm_ws              ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
JOIN   web_site wsite               ON ws.ws_web_site_sk = wsite.web_site_sk
LEFT   OUTER JOIN web_returns wr    ON wr.wr_order_number = ws.ws_order_number
JOIN   web_page wp                  ON ws.ws_web_page_sk = wp.wp_web_page_sk
WHERE  cc.cc_country = 'United States'
  AND  wsite.web_company_id = 3
  AND  hd.hd_vehicle_count >= 2
  AND  wsite.web_rec_start_date >= DATE '2001-01-01'
ORDER BY cs_agg.total_cs_net_paid DESC
LIMIT 100
