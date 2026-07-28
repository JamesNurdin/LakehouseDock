WITH base AS (
    SELECT
        s.s_store_id,
        d_ws.d_year,
        i.i_item_id,
        i.i_brand,
        i.i_category,
        ws.ws_quantity,
        ws.ws_ext_sales_price,
        ws.ws_net_profit,
        p.p_promo_id,
        p.p_cost,
        CASE WHEN p.p_discount_active = 'Y' THEN 'Active' ELSE 'Inactive' END AS promo_status,
        r_sr.r_reason_desc      AS store_return_reason,
        r_cr.r_reason_desc      AS catalog_return_reason,
        cc.cc_name,
        cp.cp_department,
        wp.wp_type,
        inv.inv_quantity_on_hand,
        cr.cr_return_quantity,
        sr.sr_return_quantity,
        time_ws.t_hour,
        cd.cd_gender,
        hd.hd_income_band_sk,
        ws.ws_order_number
    FROM web_sales ws
    JOIN date_dim d_ws ON ws.ws_sold_date_sk = d_ws.d_date_sk
    JOIN time_dim time_ws ON ws.ws_sold_time_sk = time_ws.t_time_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk AND inv.inv_date_sk = d_ws.d_date_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    -- store returns side
    JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk
    JOIN date_dim d_sr ON sr.sr_returned_date_sk = d_sr.d_date_sk
    JOIN time_dim time_sr ON sr.sr_return_time_sk = time_sr.t_time_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN reason r_sr ON sr.sr_reason_sk = r_sr.r_reason_sk
    -- catalog returns side
    JOIN catalog_returns cr ON cr.cr_item_sk = i.i_item_sk
    JOIN date_dim d_cr ON cr.cr_returned_date_sk = d_cr.d_date_sk
    JOIN time_dim time_cr ON cr.cr_returned_time_sk = time_cr.t_time_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN reason r_cr ON cr.cr_reason_sk = r_cr.r_reason_sk
    WHERE d_ws.d_year BETWEEN 2000 AND 2002
      AND i.i_brand = 'Brand#12'
      AND p.p_cost > 500
      AND s.s_state = 'TX'
      AND cc.cc_gmt_offset BETWEEN -6 AND -4
      AND time_ws.t_hour BETWEEN 9 AND 17
      AND inv.inv_quantity_on_hand > 0
      AND cp.cp_department = 'Sports'
),
agg_by_store_year AS (
    SELECT
        s_store_id,
        d_year,
        SUM(ws_ext_sales_price)               AS total_sales,
        SUM(ws_net_profit)                    AS total_profit,
        SUM(sr_return_quantity)               AS total_store_returns,
        SUM(cr_return_quantity)               AS total_catalog_returns,
        COUNT(DISTINCT ws_order_number)       AS order_cnt,
        AVG(p_cost)                           AS avg_promo_cost
    FROM base
    GROUP BY s_store_id, d_year
)
SELECT
    agg.s_store_id,
    agg.d_year,
    agg.total_sales,
    agg.total_profit,
    agg.total_store_returns,
    agg.total_catalog_returns,
    agg.order_cnt,
    agg.avg_promo_cost,
    agg.total_profit / NULLIF(agg.total_sales, 0)                AS profit_margin,
    ROW_NUMBER() OVER (PARTITION BY agg.s_store_id ORDER BY agg.total_profit DESC) AS profit_rank,
    (SELECT AVG(total_profit) FROM agg_by_store_year ay2 WHERE ay2.d_year = agg.d_year) AS avg_year_profit,
    CASE WHEN agg.total_profit > 100000 THEN 'High' ELSE 'Low' END AS profit_level
FROM agg_by_store_year agg
WHERE agg.total_profit > 10000
ORDER BY agg.total_profit DESC, agg.s_store_id
LIMIT 100
