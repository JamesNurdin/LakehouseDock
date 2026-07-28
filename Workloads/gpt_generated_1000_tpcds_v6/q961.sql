/* goal: Analyze combined store and web sales profit by item category and TV promotion channel, excluding items that appear in catalog returns, and incorporating customer, demographic, inventory, and return information. */
WITH
    /* Aggregate store sales with relevant joins and filters */
    ss_agg AS (
        SELECT
            ss.ss_item_sk          AS item_sk,
            ss.ss_promo_sk         AS promo_sk,
            ss.ss_sold_date_sk     AS sold_date_sk,
            SUM(ss.ss_net_profit)  AS store_net_profit,
            SUM(ss.ss_quantity)    AS store_quantity
        FROM store_sales ss
        JOIN time_dim td               ON ss.ss_sold_time_sk = td.t_time_sk
        JOIN customer c                ON ss.ss_customer_sk = c.c_customer_sk
        JOIN customer_address ca       ON ss.ss_addr_sk = ca.ca_address_sk
        JOIN customer_demographics cd  ON ss.ss_cdemo_sk = cd.cd_demo_sk
        JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
        JOIN income_band ib            ON hd.hd_income_band_sk = ib.ib_income_band_sk
        WHERE td.t_hour BETWEEN 9 AND 17
          AND c.c_birth_year > 1970
          AND ib.ib_upper_bound <= 80000
        GROUP BY ss.ss_item_sk, ss.ss_promo_sk, ss.ss_sold_date_sk
    ),

    /* Aggregate web sales with similar joins and filters */
    ws_agg AS (
        SELECT
            ws.ws_item_sk          AS item_sk,
            ws.ws_promo_sk         AS promo_sk,
            ws.ws_sold_date_sk     AS sold_date_sk,
            SUM(ws.ws_net_profit)  AS web_net_profit,
            SUM(ws.ws_quantity)    AS web_quantity
        FROM web_sales ws
        JOIN time_dim td               ON ws.ws_sold_time_sk = td.t_time_sk
        JOIN customer bc               ON ws.ws_bill_customer_sk = bc.c_customer_sk
        JOIN customer sc               ON ws.ws_ship_customer_sk = sc.c_customer_sk
        JOIN customer_address ba       ON ws.ws_bill_addr_sk = ba.ca_address_sk
        JOIN customer_address sa       ON ws.ws_ship_addr_sk = sa.ca_address_sk
        JOIN customer_demographics bcd ON ws.ws_bill_cdemo_sk = bcd.cd_demo_sk
        JOIN household_demographics bhd ON ws.ws_bill_hdemo_sk = bhd.hd_demo_sk
        JOIN income_band ib2           ON bhd.hd_income_band_sk = ib2.ib_income_band_sk
        WHERE td.t_hour BETWEEN 9 AND 17
          AND ws.ws_net_profit > 0
          AND ib2.ib_lower_bound >= 40000
        GROUP BY ws.ws_item_sk, ws.ws_promo_sk, ws.ws_sold_date_sk
    ),

    /* Catalog returns details – brings in call_center, catalog_page and ship_mode */
    catalog_ret AS (
        SELECT
            cr.cr_item_sk,
            cr.cr_return_amount,
            cc.cc_zip,
            cp.cp_department,
            sm.sm_type
        FROM catalog_returns cr
        JOIN call_center cc   ON cr.cr_call_center_sk = cc.cc_call_center_sk
        JOIN catalog_page cp  ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
        JOIN ship_mode sm     ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
        WHERE cc.cc_zip = '33451'
          AND cp.cp_department = 'Electronics'
          AND sm.sm_type = 'AIR'
    ),

    /* Store returns aggregated per item */
    store_ret AS (
        SELECT
            sr.sr_item_sk,
            SUM(sr.sr_net_loss)          AS total_net_loss,
            MAX(sr.sr_return_quantity)   AS max_return_qty
        FROM store_returns sr
        JOIN time_dim td ON sr.sr_return_time_sk = td.t_time_sk
        WHERE td.t_hour BETWEEN 9 AND 17
        GROUP BY sr.sr_item_sk
    ),

    /* Inventory totals per item */
    inv_agg AS (
        SELECT
            inv_item_sk,
            SUM(inv_quantity_on_hand) AS total_on_hand
        FROM inventory
        GROUP BY inv_item_sk
    )

SELECT
    i.i_category,
    p.p_channel_tv,
    SUM(COALESCE(agg.store_net_profit, 0) + COALESCE(agg.web_net_profit, 0)) AS total_net_profit,
    SUM(COALESCE(agg.store_quantity, 0) + COALESCE(agg.web_quantity, 0))   AS total_quantity,
    MAX(inv.total_on_hand)                                                   AS max_quantity_on_hand,
    COUNT(DISTINCT CASE WHEN cr.cr_item_sk IS NOT NULL THEN cr.cr_item_sk END) AS catalog_returned_items,
    MAX(sr.total_net_loss)                                                    AS max_store_return_loss
FROM (
        SELECT item_sk, promo_sk, sold_date_sk, store_net_profit, store_quantity, NULL AS web_net_profit, NULL AS web_quantity
        FROM ss_agg
        UNION ALL
        SELECT item_sk, promo_sk, sold_date_sk, NULL, NULL, web_net_profit, web_quantity
        FROM ws_agg
     ) agg
JOIN item i                ON agg.item_sk = i.i_item_sk
JOIN promotion p           ON agg.promo_sk = p.p_promo_sk AND p.p_item_sk = i.i_item_sk
LEFT JOIN inv_agg inv      ON i.i_item_sk = inv.inv_item_sk
LEFT JOIN catalog_ret cr   ON i.i_item_sk = cr.cr_item_sk
LEFT JOIN store_ret sr     ON i.i_item_sk = sr.sr_item_sk
WHERE NOT EXISTS (
        SELECT 1 FROM catalog_ret cr_ex
        WHERE cr_ex.cr_item_sk = agg.item_sk
      )
  AND i.i_current_price BETWEEN 50 AND 200
  AND p.p_discount_active = 'N'
GROUP BY i.i_category, p.p_channel_tv
ORDER BY total_net_profit DESC
LIMIT 100
