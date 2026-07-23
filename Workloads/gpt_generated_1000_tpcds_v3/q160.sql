WITH item_sales AS (
    SELECT
        i.i_item_id,
        i.i_product_name,
        s.s_store_id,
        s.s_store_name,
        s.s_division_id,
        s.s_division_name,
        s.s_state,
        hd.hd_demo_sk,
        hd.hd_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        p.p_promo_id,
        wsit.web_site_id,
        SUM(ss.ss_net_paid_inc_tax) AS store_net_paid,
        SUM(ss.ss_net_profit) AS store_net_profit,
        SUM(ws.ws_net_paid_inc_ship_tax) AS web_net_paid,
        SUM(ws.ws_net_profit) AS web_net_profit,
        COUNT(DISTINCT p.p_promo_id) AS distinct_promo_cnt
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
    JOIN web_site wsit ON ws.ws_web_site_sk = wsit.web_site_sk
    WHERE s.s_state = 'CA'
      AND i.i_category = 'Sports'
      AND ib.ib_lower_bound >= 50000
      AND p.p_discount_active = 'Y'
      AND ss.ss_net_paid_inc_tax > 1000
      AND ws.ws_net_paid_inc_ship_tax > 1000
    GROUP BY
        i.i_item_id,
        i.i_product_name,
        s.s_store_id,
        s.s_store_name,
        s.s_division_id,
        s.s_division_name,
        s.s_state,
        hd.hd_demo_sk,
        hd.hd_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        p.p_promo_id,
        wsit.web_site_id
)
SELECT
    i_item_id,
    i_product_name,
    s_store_id,
    s_store_name,
    s_division_name,
    s_state,
    store_net_paid,
    web_net_paid,
    (store_net_paid + web_net_paid) AS total_net_paid,
    store_net_profit,
    web_net_profit,
    (store_net_profit + web_net_profit) AS total_net_profit,
    distinct_promo_cnt,
    CASE
        WHEN (store_net_profit + web_net_profit) > (
            SELECT AVG(item_total_profit)
            FROM (
                SELECT i.i_item_sk,
                       SUM(ss.ss_net_profit + ws.ws_net_profit) AS item_total_profit
                FROM store_sales ss
                JOIN item i ON ss.ss_item_sk = i.i_item_sk
                JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
                GROUP BY i.i_item_sk
            ) t
        ) THEN 'High'
        ELSE 'Normal'
    END AS profit_flag,
    RANK() OVER (PARTITION BY s_division_name ORDER BY (store_net_profit + web_net_profit) DESC) AS profit_rank
FROM item_sales
ORDER BY total_net_profit DESC
LIMIT 100
