/*
Goal: Identify the most profitable item‑promotion‑call‑center combinations across all sales channels (catalog, store, web), after filtering for high‑price items, active promotions, a specific state, monthly catalog pages, and a moderate income band. The query first joins all 11 TPC‑DS tables using only the allowed join keys, aggregates sales and returns per combination in a CTE, then computes profit, ranks the results, adds a cumulative‑sales window, filters out non‑profitable rows, orders by profit, and limits to the top 100.
*/
WITH joined_data AS (
    SELECT
        i.i_item_id,
        p.p_promo_id,
        cc.cc_call_center_id,
        cs.cs_net_paid,
        ss.ss_net_paid,
        ws.ws_net_paid,
        cr.cr_return_amount,
        cs.cs_order_number
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN store_sales ss ON ss.ss_item_sk = i.i_item_sk
        AND ss.ss_hdemo_sk = hd.hd_demo_sk
        AND ss.ss_promo_sk = p.p_promo_sk
    LEFT JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
        AND ws.ws_bill_hdemo_sk = hd.hd_demo_sk
        AND ws.ws_promo_sk = p.p_promo_sk
    LEFT JOIN catalog_returns cr ON cr.cr_item_sk = i.i_item_sk
        AND cr.cr_order_number = cs.cs_order_number
    WHERE
        i.i_current_price > 50
        AND p.p_discount_active = 'Y'
        AND cc.cc_state = 'CA'
        AND cp.cp_type = 'monthly'
        AND ib.ib_upper_bound <= 100000
        AND cs.cs_sold_date_sk BETWEEN 2450800 AND 2450900
),
item_agg AS (
    SELECT
        i_item_id,
        p_promo_id,
        cc_call_center_id,
        SUM(cs_net_paid) AS sum_cs_sales,
        SUM(ss_net_paid) AS sum_ss_sales,
        SUM(ws_net_paid) AS sum_ws_sales,
        SUM(cr_return_amount) AS sum_returns,
        COUNT(DISTINCT cs_order_number) AS order_cnt
    FROM joined_data
    GROUP BY i_item_id, p_promo_id, cc_call_center_id
)
SELECT
    i_item_id,
    p_promo_id,
    cc_call_center_id,
    (sum_cs_sales + sum_ss_sales + sum_ws_sales) AS total_sales,
    sum_returns,
    (sum_cs_sales + sum_ss_sales + sum_ws_sales - sum_returns) AS profit,
    order_cnt,
    SUM(sum_cs_sales + sum_ss_sales + sum_ws_sales) OVER (
        ORDER BY (sum_cs_sales + sum_ss_sales + sum_ws_sales) DESC
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_sales,
    RANK() OVER (ORDER BY (sum_cs_sales + sum_ss_sales + sum_ws_sales - sum_returns) DESC) AS profit_rank
FROM item_agg
WHERE (sum_cs_sales + sum_ss_sales + sum_ws_sales - sum_returns) > 0
ORDER BY profit DESC
LIMIT 100
