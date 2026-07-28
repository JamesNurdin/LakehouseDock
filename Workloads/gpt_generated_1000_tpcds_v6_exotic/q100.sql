WITH base AS (
    SELECT
        cs.cs_order_number,
        cs.cs_ext_sales_price,
        cs.cs_net_profit,
        cs.cs_quantity,
        td_cs.t_hour AS cs_hour,
        td_cs.t_am_pm AS cs_am_pm,
        c.c_customer_id,
        cd.cd_gender,
        hd.hd_income_band_sk,
        i.i_item_sk,
        i.i_category,
        i.i_brand,
        i.i_current_price,
        p.p_promo_id,
        p.p_discount_active,
        s.s_store_id,
        s.s_state,
        r.r_reason_desc,
        inv.inv_quantity_on_hand,
        wp.wp_url,
        ws.ws_sold_date_sk,
        wr.wr_return_quantity,
        wr.wr_return_amt
    FROM catalog_sales cs
    JOIN time_dim td_cs
        ON cs.cs_sold_time_sk = td_cs.t_time_sk
    JOIN customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd
        ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    JOIN inventory inv
        ON i.i_item_sk = inv.inv_item_sk
    JOIN store_returns sr
        ON sr.sr_item_sk = i.i_item_sk
    JOIN time_dim td_sr
        ON sr.sr_return_time_sk = td_sr.t_time_sk
    JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    JOIN reason r
        ON sr.sr_reason_sk = r.r_reason_sk
    JOIN web_sales ws
        ON ws.ws_item_sk = i.i_item_sk
        AND ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN time_dim td_ws
        ON ws.ws_sold_time_sk = td_ws.t_time_sk
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_returns wr
        ON wr.wr_order_number = ws.ws_order_number
    JOIN time_dim td_wr
        ON wr.wr_returned_time_sk = td_wr.t_time_sk
    WHERE i.i_current_price > 100
      AND i.i_brand = 'BrandX'
      AND p.p_discount_active = 'Y'
      AND td_cs.t_am_pm = 'PM'
      AND s.s_state = 'CA'
      AND inv.inv_quantity_on_hand > 0
      AND EXISTS (
          SELECT 1
          FROM promotion p2
          WHERE p2.p_promo_sk = cs.cs_promo_sk
            AND p2.p_response_target > 5
      )
),
agg AS (
    SELECT
        i_category,
        i_brand,
        SUM(cs_net_profit) AS total_profit,
        SUM(cs_quantity) AS total_quantity,
        COUNT(DISTINCT cs_order_number) AS order_cnt
    FROM base
    GROUP BY i_category, i_brand
    HAVING SUM(cs_net_profit) > 1000
)
SELECT
    i_category,
    i_brand,
    total_profit,
    total_quantity,
    order_cnt,
    total_profit / NULLIF(total_quantity, 0) AS profit_per_unit
FROM agg
ORDER BY total_profit DESC
LIMIT 100
