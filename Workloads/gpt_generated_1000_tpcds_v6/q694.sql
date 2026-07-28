-- goal: Rank web sales net profit by item category while integrating returns, promotions, demographics and location filters
WITH catalog_agg AS (
    SELECT
        cr.cr_item_sk AS item_sk,
        SUM(cr.cr_return_amount) AS total_return_amount,
        COUNT(*) AS return_cnt
    FROM catalog_returns cr
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    WHERE cc.cc_state = 'CA'                     -- filter 1
      AND cr.cr_return_quantity > 1              -- filter 2
    GROUP BY cr.cr_item_sk
)
SELECT
    ws.ws_order_number,
    i.i_item_id,
    i.i_category,
    i.i_brand,
    p.p_promo_name,
    cc.cc_name            AS call_center_name,
    cp.cp_catalog_number,
    cp.cp_catalog_page_number,
    ws.ws_net_profit,
    ws.ws_net_paid,
    RANK() OVER (PARTITION BY i.i_category ORDER BY ws.ws_net_profit DESC) AS profit_rank_by_category,
    CASE
        WHEN ws.ws_net_profit > 0 THEN 'POSITIVE'
        ELSE 'NON_POSITIVE'
    END AS profit_flag,
    (
        SELECT COUNT(*)
        FROM store_returns sr_sub
        WHERE sr_sub.sr_item_sk = ws.ws_item_sk
          AND sr_sub.sr_return_quantity > 3
    ) AS high_return_count,
    caa.total_return_amount,
    caa.return_cnt
FROM web_sales ws
JOIN item i                     ON ws.ws_item_sk = i.i_item_sk
JOIN time_dim t                 ON ws.ws_sold_time_sk = t.t_time_sk
JOIN customer c                ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
JOIN customer_address ca       ON ws.ws_bill_addr_sk = ca.ca_address_sk
JOIN promotion p               ON ws.ws_promo_sk = p.p_promo_sk
JOIN web_page wp               ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN ship_mode sm              ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w               ON ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN catalog_returns cr        ON cr.cr_item_sk = i.i_item_sk
JOIN catalog_page cp           ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN call_center cc            ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN store_returns sr          ON sr.sr_item_sk = i.i_item_sk
JOIN catalog_agg caa           ON caa.item_sk = i.i_item_sk
WHERE i.i_category_id IN (1, 2, 4)                     -- filter 3
  AND t.t_hour BETWEEN 9 AND 17                         -- filter 4
  AND c.c_birth_year BETWEEN 1950 AND 1970              -- filter 5
  AND sm.sm_type = 'AIR'                                -- filter 6
  AND w.w_state = 'TX'                                  -- filter 7
ORDER BY profit_rank_by_category, ws.ws_order_number
LIMIT 100
