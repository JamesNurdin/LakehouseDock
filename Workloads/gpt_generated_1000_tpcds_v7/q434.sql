WITH joined_data AS (
    SELECT
        cs.cs_order_number,
        cs.cs_sold_date_sk,
        cs.cs_quantity,
        cs.cs_ext_sales_price,
        ws.ws_order_number,
        ws.ws_ext_sales_price,
        ws.ws_net_paid,
        i.i_item_id,
        i.i_brand,
        i.i_category,
        hd.hd_buy_potential,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        inv.inv_quantity_on_hand,
        sm.sm_ship_mode_id,
        sm.sm_type,
        p.p_promo_name,
        p.p_discount_active,
        t.t_hour,
        -- correlated sub‑query for promo flag
        CASE WHEN EXISTS (
                 SELECT 1
                 FROM promotion p2
                 WHERE p2.p_item_sk = i.i_item_sk
                   AND p2.p_discount_active = 'Y'
               )
            THEN 'HasActivePromo'
            ELSE 'NoPromo'
       END AS promo_flag,
        -- window rank per category by total sales price
        ROW_NUMBER() OVER (
            PARTITION BY i.i_category
            ORDER BY (cs.cs_ext_sales_price + ws.ws_ext_sales_price) DESC
        ) AS sales_rank
    FROM catalog_sales cs
    JOIN time_dim t
      ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN ship_mode sm
      ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN item i
      ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p
      ON cs.cs_promo_sk = p.p_promo_sk
    JOIN household_demographics hd
      ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
      ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN inventory inv
      ON i.i_item_sk = inv.inv_item_sk
    JOIN web_sales ws
      ON t.t_time_sk = ws.ws_sold_time_sk
    JOIN web_page wp
      ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site wsite
      ON ws.ws_web_site_sk = wsite.web_site_sk
    WHERE cs.cs_sold_date_sk BETWEEN 2450000 AND 2451000
      AND cs.cs_quantity > 1
      AND i.i_brand = 'Brand#12'
      AND p.p_discount_active = 'Y'
      AND sm.sm_type = 'AIR'
      AND ib.ib_upper_bound >= 100000
      AND ws.ws_net_paid > 1000
      AND t.t_hour BETWEEN 8 AND 17
) 
SELECT
    cs_order_number,
    cs_sold_date_sk,
    i_item_id,
    i_brand,
    i_category,
    hd_buy_potential,
    ib_lower_bound,
    ib_upper_bound,
    inv_quantity_on_hand,
    sm_ship_mode_id,
    sm_type,
    p_promo_name,
    ws_order_number,
    ws_net_paid,
    promo_flag,
    sales_rank
FROM joined_data
ORDER BY sales_rank ASC
LIMIT 100
