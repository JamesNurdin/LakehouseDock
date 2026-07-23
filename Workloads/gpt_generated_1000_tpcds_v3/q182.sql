WITH
    catalog_agg AS (
        SELECT
            cs_call_center_sk,
            cs_item_sk,
            cs_sold_date_sk,
            cs_order_number,
            cs_promo_sk,
            cs_ship_mode_sk,
            cs_warehouse_sk,
            cs_bill_customer_sk,
            cs_bill_cdemo_sk,
            cs_bill_hdemo_sk,
            cs_bill_addr_sk,
            SUM(cs_net_paid)               AS total_net_paid,
            SUM(cs_ext_sales_price)        AS total_sales_price,
            COUNT(*)                       AS order_cnt
        FROM catalog_sales
        WHERE cs_quantity > 1
        GROUP BY cs_call_center_sk, cs_item_sk, cs_sold_date_sk, cs_order_number,
                 cs_promo_sk, cs_ship_mode_sk, cs_warehouse_sk,
                 cs_bill_customer_sk, cs_bill_cdemo_sk, cs_bill_hdemo_sk, cs_bill_addr_sk
    ),
    store_sales_agg AS (
        SELECT
            ss_store_sk,
            ss_item_sk,
            ss_sold_date_sk,
            ss_promo_sk,
            ss_ticket_number,
            ss_customer_sk,
            ss_cdemo_sk,
            ss_hdemo_sk,
            ss_addr_sk,
            SUM(ss_ext_sales_price) AS store_total_sales,
            SUM(ss_net_profit)      AS store_total_profit,
            COUNT(*)                AS store_txn_cnt
        FROM store_sales
        WHERE ss_quantity > 0
          AND ss_list_price > 20
        GROUP BY ss_store_sk, ss_item_sk, ss_sold_date_sk,
                 ss_promo_sk, ss_ticket_number,
                 ss_customer_sk, ss_cdemo_sk, ss_hdemo_sk, ss_addr_sk
    ),
    web_sales_agg AS (
        SELECT
            ws_item_sk,
            ws_sold_date_sk,
            ws_order_number,
            ws_promo_sk,
            ws_ship_mode_sk,
            ws_warehouse_sk,
            ws_bill_customer_sk,
            ws_bill_cdemo_sk,
            ws_bill_hdemo_sk,
            ws_bill_addr_sk,
            SUM(ws_net_paid) AS web_total_net_paid,
            COUNT(*)         AS web_order_cnt
        FROM web_sales
        WHERE ws_quantity > 0
        GROUP BY ws_item_sk, ws_sold_date_sk, ws_order_number,
                 ws_promo_sk, ws_ship_mode_sk, ws_warehouse_sk,
                 ws_bill_customer_sk, ws_bill_cdemo_sk, ws_bill_hdemo_sk, ws_bill_addr_sk
    ),
    common_orders AS (
        SELECT cs_order_number AS order_id FROM catalog_sales
        INTERSECT
        SELECT ws_order_number FROM web_sales
    )
SELECT
    d.d_year,
    s.s_store_name,
    i.i_item_id,
    i.i_brand,
    cc.cc_name               AS call_center_name,
    p.p_promo_name,
    sm.sm_type               AS ship_mode_type,
    w.w_warehouse_name,
    hd.hd_buy_potential,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    ss.store_total_sales,
    ss.store_total_profit,
    ca.total_net_paid        AS catalog_total_net_paid,
    ws.web_total_net_paid,
    CASE
        WHEN ss.store_total_profit > 1000 THEN 'High'
        WHEN ss.store_total_profit > 0    THEN 'Medium'
        ELSE 'Low'
    END                     AS profit_category,
    RANK() OVER (PARTITION BY d.d_year ORDER BY ss.store_total_profit DESC) AS profit_rank_year,
    (SELECT AVG(i2.i_current_price)
     FROM item i2
     WHERE i2.i_brand = i.i_brand) AS avg_brand_price
FROM store_sales_agg ss
JOIN date_dim d               ON ss.ss_sold_date_sk = d.d_date_sk
JOIN store s                  ON ss.ss_store_sk = s.s_store_sk
JOIN item i                   ON ss.ss_item_sk = i.i_item_sk
JOIN promotion p              ON ss.ss_promo_sk = p.p_promo_sk
JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib           ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN customer c               ON ss.ss_customer_sk = c.c_customer_sk
JOIN customer_address ca_addr ON ss.ss_addr_sk = ca_addr.ca_address_sk
JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
LEFT JOIN store_returns sr    ON sr.sr_ticket_number = ss.ss_ticket_number
                               AND sr.sr_item_sk = ss.ss_item_sk
                               AND sr.sr_store_sk = s.s_store_sk
JOIN catalog_agg ca           ON ca.cs_item_sk = i.i_item_sk
                               AND ca.cs_sold_date_sk = d.d_date_sk
                               AND ca.cs_promo_sk = p.p_promo_sk
                               AND ca.cs_bill_customer_sk = c.c_customer_sk
                               AND ca.cs_bill_cdemo_sk = cd.cd_demo_sk
                               AND ca.cs_bill_hdemo_sk = hd.hd_demo_sk
                               AND ca.cs_bill_addr_sk = ca_addr.ca_address_sk
JOIN call_center cc          ON ca.cs_call_center_sk = cc.cc_call_center_sk
JOIN ship_mode sm            ON ca.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w             ON ca.cs_warehouse_sk = w.w_warehouse_sk
JOIN web_sales_agg ws        ON ws.ws_item_sk = i.i_item_sk
                               AND ws.ws_sold_date_sk = d.d_date_sk
                               AND ws.ws_promo_sk = p.p_promo_sk
                               AND ws.ws_bill_customer_sk = c.c_customer_sk
                               AND ws.ws_bill_cdemo_sk = cd.cd_demo_sk
                               AND ws.ws_bill_hdemo_sk = hd.hd_demo_sk
                               AND ws.ws_bill_addr_sk = ca_addr.ca_address_sk
WHERE d.d_year = 2001
  AND s.s_state = 'CA'
  AND p.p_channel_demo = 'N'
  AND i.i_current_price > 50
  AND ib.ib_lower_bound >= 30000
  AND EXISTS (SELECT 1 FROM store_returns sr2 WHERE sr2.sr_ticket_number = ss.ss_ticket_number)
  AND ca.cs_order_number IN (SELECT order_id FROM common_orders)
ORDER BY ss.store_total_profit DESC
LIMIT 100
