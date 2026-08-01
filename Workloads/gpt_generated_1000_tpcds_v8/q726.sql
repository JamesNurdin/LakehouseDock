WITH chain AS (
    SELECT
        cs.cs_order_number                     AS cs_order_number,
        cs.cs_net_profit                       AS cs_net_profit,
        cs.cs_promo_sk                         AS cs_promo_sk,
        cs.cs_warehouse_sk                     AS cs_warehouse_sk,
        cs.cs_sold_time_sk                     AS cs_sold_time_sk,
        cs.cs_call_center_sk                   AS cs_call_center_sk,
        cs.cs_bill_cdemo_sk                    AS cs_bill_cdemo_sk,
        cs.cs_bill_hdemo_sk                    AS cs_bill_hdemo_sk,
        cs.cs_bill_addr_sk                     AS cs_bill_addr_sk,
        p.p_promo_id                           AS cs_promo_id,
        p.p_discount_active                    AS cs_promo_active,
        cc.cc_country                           AS cc_country,
        cd.cd_gender                           AS cd_gender,
        hd.hd_income_band_sk                   AS hd_income_band_sk,
        ib.ib_upper_bound                      AS income_band_upper,
        inv.inv_quantity_on_hand               AS inv_quantity_on_hand,
        sm.sm_ship_mode_id                     AS ship_mode_id,
        w.w_warehouse_name                     AS warehouse_name,
        s.s_store_name                         AS store_name,
        ca2.ca_city                            AS ss_ship_city,
        p2.p_promo_id                          AS ss_promo_id,
        ss.ss_net_profit                       AS ss_net_profit,
        ws.ws_net_profit                       AS ws_net_profit,
        ws.ws_order_number                     AS ws_order_number,
        p3.p_promo_id                          AS ws_promo_id,
        -- LATERAL sub‑query: total inventory in the same warehouse
        l_inv.inv_qty_sum                       AS total_inventory_qty
    FROM catalog_sales cs
    JOIN time_dim td                     ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN call_center cc                  ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN promotion p                     ON cs.cs_promo_sk = p.p_promo_sk
    JOIN ship_mode sm                    ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w                     ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN customer_demographics cd        ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca1            ON cs.cs_bill_addr_sk = ca1.ca_address_sk
    LEFT JOIN inventory inv              ON inv.inv_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN income_band ib             ON hd.hd_income_band_sk = ib.ib_income_band_sk
    FULL OUTER JOIN store_sales ss       ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN store s                         ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p2                    ON ss.ss_promo_sk = p2.p_promo_sk
    JOIN customer_address ca2            ON ss.ss_addr_sk = ca2.ca_address_sk
    LEFT JOIN web_sales ws              ON ws.ws_sold_time_sk = td.t_time_sk
    LEFT JOIN promotion p3               ON ws.ws_promo_sk = p3.p_promo_sk
    LEFT JOIN web_page wp                ON ws.ws_web_page_sk = wp.wp_web_page_sk
    CROSS JOIN LATERAL (
        SELECT sum(inv3.inv_quantity_on_hand) AS inv_qty_sum
        FROM   inventory inv3
        WHERE  inv3.inv_warehouse_sk = w.w_warehouse_sk
    ) l_inv
    WHERE cs.cs_call_center_sk IN (
        SELECT cc2.cc_call_center_sk
        FROM   call_center cc2
        WHERE  cc2.cc_country = 'USA'
    )
      AND NOT EXISTS (                                   -- anti‑join: exclude promotions that are currently active
        SELECT 1
        FROM   promotion p_ex
        WHERE  p_ex.p_promo_id = p.p_promo_id
          AND  p_ex.p_discount_active = 'Y'
      )
)
-- Union two logical “views” (catalog side and web‑sales side) and deduplicate
SELECT promo_id,
       store_name,
       SUM(profit) AS total_profit
FROM (
    SELECT cs_promo_id   AS promo_id,
           store_name    AS store_name,
           cs_net_profit AS profit
    FROM   chain
    WHERE  cs_net_profit IS NOT NULL

    UNION

    SELECT ws_promo_id   AS promo_id,
           store_name    AS store_name,
           ws_net_profit AS profit
    FROM   chain
    WHERE  ws_net_profit IS NOT NULL
) u
GROUP BY promo_id, store_name
HAVING SUM(profit) > 1000
ORDER BY total_profit DESC
LIMIT 100
