WITH sales_enhanced AS (
    SELECT
        ws.ws_order_number,
        ws.ws_sold_date_sk,
        ws.ws_sold_time_sk,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_sales_price,
        ws.ws_net_profit,
        i.i_category,
        i.i_brand,
        i.i_current_price,
        c.c_first_name,
        c.c_last_name,
        ca.ca_state,
        hd.hd_income_band_sk,
        sm.sm_type AS ship_type,
        p.p_discount_active,
        t.t_hour,
        inv.inv_quantity_on_hand,
        cr.cr_return_amount,
        cp.cp_department,
        sr.sr_return_quantity,
        r.r_reason_desc,
        wsit.web_name
    FROM web_sales ws
    JOIN item i                     ON ws.ws_item_sk = i.i_item_sk
    JOIN customer c                 ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca        ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd  ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN ship_mode sm               ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN promotion p                ON ws.ws_promo_sk = p.p_promo_sk
    JOIN time_dim t                 ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN web_site wsit              ON ws.ws_web_site_sk = wsit.web_site_sk
    LEFT JOIN inventory inv         ON inv.inv_item_sk = ws.ws_item_sk
    LEFT JOIN catalog_returns cr    ON cr.cr_item_sk = ws.ws_item_sk AND cr.cr_returned_time_sk = ws.ws_sold_time_sk
    LEFT JOIN catalog_page cp       ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    LEFT JOIN store_returns sr      ON sr.sr_item_sk = ws.ws_item_sk AND sr.sr_return_time_sk = ws.ws_sold_time_sk
    LEFT JOIN reason r              ON sr.sr_reason_sk = r.r_reason_sk
    WHERE ws.ws_sold_date_sk BETWEEN 2451545 AND 2451910
      AND i.i_category_id IN (1, 2, 3)
      AND ca.ca_state = 'CA'
      AND p.p_discount_active = 'Y'
      AND sm.sm_type = 'AIR'
      AND inv.inv_quantity_on_hand > 0
)
SELECT
    se.ws_order_number,
    se.ws_sold_date_sk,
    se.i_category,
    se.i_brand,
    se.c_first_name,
    se.c_last_name,
    CASE WHEN se.ws_net_profit > 1000 THEN 'HIGH' ELSE 'NORMAL' END AS profit_category,
    SUM(se.ws_sales_price) OVER (
        PARTITION BY se.i_category
        ORDER BY se.ws_sold_date_sk
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_category_sales,
    ROW_NUMBER() OVER (
        PARTITION BY se.i_category
        ORDER BY se.ws_net_profit DESC
    ) AS profit_rank,
    se.inv_quantity_on_hand,
    se.cr_return_amount,
    se.cp_department,
    se.sr_return_quantity,
    se.r_reason_desc,
    se.web_name,
    EXISTS (
        SELECT 1 FROM web_returns wr
        WHERE wr.wr_item_sk = se.ws_item_sk
          AND wr.wr_returned_time_sk = se.ws_sold_time_sk
          AND wr.wr_account_credit > 0
    ) AS has_web_credit_return,
    EXISTS (
        SELECT 1 FROM catalog_returns cr2
        JOIN call_center cc ON cr2.cr_call_center_sk = cc.cc_call_center_sk
        WHERE cr2.cr_item_sk = se.ws_item_sk
          AND cr2.cr_returned_time_sk = se.ws_sold_time_sk
          AND cc.cc_country = 'USA'
    ) AS returned_via_call_center_usa
FROM sales_enhanced se
WHERE EXISTS (
    SELECT 1 FROM store_returns sr2
    WHERE sr2.sr_item_sk = se.ws_item_sk
      AND sr2.sr_return_time_sk = se.ws_sold_time_sk
      AND sr2.sr_return_quantity > 0
)
ORDER BY se.ws_sold_date_sk DESC, profit_rank ASC
LIMIT 100
