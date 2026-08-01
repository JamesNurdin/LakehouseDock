WITH
ss AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_sold_time_sk,
        ss.ss_item_sk,
        ss.ss_store_sk,
        ss.ss_promo_sk,
        ss.ss_ticket_number,
        ss.ss_quantity,
        ss.ss_net_profit,
        d.d_year,
        i.i_category,
        s.s_store_name,
        p.p_promo_name,
        ca.ca_state,
        cd.cd_gender
    FROM store_sales ss
    JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t
        ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
      AND s.s_state = 'CA'
      AND ca.ca_state = 'CA'
      AND cd.cd_gender = 'M'
      AND p.p_channel_press = 'N'
      AND i.i_color = 'Red'
      AND t.t_hour BETWEEN 9 AND 17
),

ws AS (
    SELECT
        ws.ws_sold_date_sk,
        ws.ws_sold_time_sk,
        ws.ws_item_sk,
        ws.ws_warehouse_sk,
        ws.ws_promo_sk,
        ws.ws_quantity,
        ws.ws_net_profit,
        d.d_year,
        i.i_category,
        w.w_warehouse_name,
        p.p_promo_name,
        ca.ca_city,
        cd.cd_gender AS bill_gender
    FROM web_sales ws
    JOIN date_dim d
        ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN time_dim t
        ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN item i
        ON ws.ws_item_sk = i.i_item_sk
    JOIN warehouse w
        ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN promotion p
        ON ws.ws_promo_sk = p.p_promo_sk
    JOIN customer_address ca
        ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd
        ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
      AND w.w_state = 'WA'
      AND ca.ca_city = 'Seattle'
      AND cd.cd_gender = 'F'
      AND p.p_discount_active = 'Y'
      AND t.t_hour BETWEEN 9 AND 17
),

sr AS (
    SELECT
        sr.sr_returned_date_sk,
        sr.sr_return_time_sk,
        sr.sr_item_sk,
        sr.sr_store_sk,
        sr.sr_reason_sk,
        sr.sr_return_quantity,
        sr.sr_net_loss,
        d.d_year,
        i.i_category,
        r.r_reason_desc,
        s.s_store_name
    FROM store_returns sr
    JOIN date_dim d
        ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN time_dim t
        ON sr.sr_return_time_sk = t.t_time_sk
    JOIN item i
        ON sr.sr_item_sk = i.i_item_sk
    JOIN reason r
        ON sr.sr_reason_sk = r.r_reason_sk
    JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
      AND s.s_state = 'CA'
      AND r.r_reason_desc LIKE '%Damaged%'
      AND t.t_hour BETWEEN 9 AND 17
),

cr AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_returned_time_sk,
        cr.cr_item_sk,
        cr.cr_warehouse_sk,
        cr.cr_reason_sk,
        cr.cr_return_quantity,
        cr.cr_net_loss,
        d.d_year,
        i.i_category,
        r.r_reason_desc,
        w.w_warehouse_name,
        cp.cp_type,
        cr.cr_call_center_sk
    FROM catalog_returns cr
    JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN time_dim t
        ON cr.cr_returned_time_sk = t.t_time_sk
    JOIN item i
        ON cr.cr_item_sk = i.i_item_sk
    JOIN warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    JOIN catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
      AND w.w_state = 'WA'
      AND cp.cp_type = 'Catalog'
      AND t.t_hour BETWEEN 9 AND 17
      AND EXISTS (
          SELECT 1
          FROM call_center cc
          WHERE cc.cc_call_center_sk = cr.cr_call_center_sk
            AND cc.cc_state = 'CA'
            AND cc.cc_gmt_offset BETWEEN -5 AND 0
      )
),

inv AS (
    SELECT
        inv.inv_date_sk,
        inv.inv_item_sk,
        inv.inv_warehouse_sk,
        SUM(inv.inv_quantity_on_hand) AS quantity_on_hand,
        d.d_year,
        i.i_category,
        w.w_warehouse_name
    FROM inventory inv
    JOIN date_dim d
        ON inv.inv_date_sk = d.d_date_sk
    JOIN item i
        ON inv.inv_item_sk = i.i_item_sk
    JOIN warehouse w
        ON inv.inv_warehouse_sk = w.w_warehouse_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
    GROUP BY inv.inv_date_sk, inv.inv_item_sk, inv.inv_warehouse_sk, d.d_year, i.i_category, w.w_warehouse_name
),

unioned AS (
    SELECT
        d_year,
        i_category,
        s_store_name AS store_name,
        p_promo_name AS promo_name,
        NULL AS warehouse_name,
        ss_net_profit AS total_store_net_profit,
        NULL AS total_web_net_profit,
        NULL AS total_store_return_loss,
        NULL AS total_catalog_return_loss,
        NULL AS total_quantity_on_hand
    FROM ss
    UNION ALL
    SELECT
        d_year,
        i_category,
        NULL,
        p_promo_name,
        w_warehouse_name,
        NULL,
        ws_net_profit,
        NULL,
        NULL,
        NULL
    FROM ws
    UNION ALL
    SELECT
        d_year,
        i_category,
        s_store_name,
        NULL,
        NULL,
        NULL,
        NULL,
        sr_net_loss,
        NULL,
        NULL
    FROM sr
    UNION ALL
    SELECT
        d_year,
        i_category,
        NULL,
        NULL,
        w_warehouse_name,
        NULL,
        NULL,
        NULL,
        cr_net_loss,
        NULL
    FROM cr
    UNION ALL
    SELECT
        d_year,
        i_category,
        NULL,
        NULL,
        w_warehouse_name,
        NULL,
        NULL,
        NULL,
        NULL,
        quantity_on_hand
    FROM inv
),

aggregated AS (
    SELECT
        d_year,
        i_category,
        COALESCE(store_name, 'All Stores') AS store_name,
        COALESCE(promo_name, 'All Promotions') AS promo_name,
        COALESCE(warehouse_name, 'All Warehouses') AS warehouse_name,
        SUM(total_store_net_profit) AS total_store_net_profit,
        SUM(total_web_net_profit) AS total_web_net_profit,
        SUM(total_store_return_loss) AS total_store_return_loss,
        SUM(total_catalog_return_loss) AS total_catalog_return_loss,
        SUM(total_quantity_on_hand) AS total_quantity_on_hand
    FROM unioned
    GROUP BY d_year, i_category, store_name, promo_name, warehouse_name
)

SELECT
    d_year,
    i_category,
    store_name,
    promo_name,
    warehouse_name,
    total_store_net_profit,
    total_web_net_profit,
    total_store_return_loss,
    total_catalog_return_loss,
    total_quantity_on_hand,
    (total_store_net_profit + total_web_net_profit - total_store_return_loss - total_catalog_return_loss) AS net_profit,
    RANK() OVER (PARTITION BY d_year ORDER BY (total_store_net_profit + total_web_net_profit - total_store_return_loss - total_catalog_return_loss) DESC) AS profit_rank,
    CASE
        WHEN (total_store_net_profit + total_web_net_profit - total_store_return_loss - total_catalog_return_loss) > 2000000 THEN 'Very High'
        WHEN (total_store_net_profit + total_web_net_profit - total_store_return_loss - total_catalog_return_loss) > 1000000 THEN 'High'
        WHEN (total_store_net_profit + total_web_net_profit - total_store_return_loss - total_catalog_return_loss) > 500000 THEN 'Medium'
        ELSE 'Low'
    END AS profit_level
FROM aggregated
ORDER BY d_year DESC, profit_rank ASC
