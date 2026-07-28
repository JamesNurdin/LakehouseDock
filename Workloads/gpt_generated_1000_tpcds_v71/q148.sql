WITH base AS (
    SELECT
        cs.cs_order_number,
        cs.cs_net_paid,
        cs.cs_ext_discount_amt,
        cs.cs_quantity,
        cs.cs_sold_date_sk,
        cs.cs_sold_time_sk,
        cs.cs_item_sk,
        cs.cs_promo_sk,
        cs.cs_call_center_sk,
        cs.cs_ship_mode_sk,
        cs.cs_bill_customer_sk,
        cs.cs_bill_cdemo_sk,
        cs.cs_bill_hdemo_sk,
        ws.ws_order_number,
        ws.ws_net_paid,
        ws.ws_ext_discount_amt,
        ws.ws_quantity,
        ws.ws_sold_date_sk AS ws_sold_date_sk,
        ws.ws_sold_time_sk AS ws_sold_time_sk,
        ws.ws_item_sk AS ws_item_sk,
        ws.ws_promo_sk AS ws_promo_sk,
        ws.ws_ship_mode_sk AS ws_ship_mode_sk,
        ws.ws_bill_customer_sk AS ws_bill_customer_sk,
        ws.ws_bill_cdemo_sk AS ws_bill_cdemo_sk,
        ws.ws_bill_hdemo_sk AS ws_bill_hdemo_sk,
        ws.ws_web_page_sk,
        i.i_brand,
        i.i_item_sk,
        cc.cc_state,
        cc.cc_call_center_id,
        sm.sm_ship_mode_id,
        p.p_promo_id,
        d_cs.d_year,
        d_cs.d_date,
        store.s_city,
        inv.inv_quantity_on_hand,
        wp.wp_url,
        hd.hd_buy_potential,
        cd.cd_gender
    FROM catalog_sales cs
    JOIN date_dim d_cs ON cs.cs_sold_date_sk = d_cs.d_date_sk
    JOIN time_dim t_cs ON cs.cs_sold_time_sk = t_cs.t_time_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
    JOIN date_dim d_ws ON ws.ws_sold_date_sk = d_ws.d_date_sk
    JOIN time_dim t_ws ON ws.ws_sold_time_sk = t_ws.t_time_sk
    JOIN ship_mode sm_ws ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
    JOIN promotion p_ws ON ws.ws_promo_sk = p_ws.p_promo_sk
    JOIN store ON store.s_closed_date_sk = d_cs.d_date_sk
    JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk AND inv.inv_date_sk = d_cs.d_date_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN date_dim d_wp_creation ON wp.wp_creation_date_sk = d_wp_creation.d_date_sk
    WHERE d_cs.d_year = 2001
      AND i.i_brand = 'Brand#12'
      AND cs.cs_net_paid > 1000
      AND cs.cs_ext_discount_amt < 500
      AND cc.cc_state = 'CA'
      AND store.s_city = 'Seattle'
),
agg AS (
    SELECT
        d_year,
        i_brand,
        cc_state,
        s_city,
        SUM(cs_net_paid + ws_net_paid) AS total_sales,
        SUM(cs_quantity + ws_quantity) AS total_quantity,
        AVG((cs_ext_discount_amt + ws_ext_discount_amt) / 2.0) AS avg_discount,
        COUNT(DISTINCT cs_order_number) AS distinct_orders
    FROM base
    GROUP BY ROLLUP (d_year, i_brand, cc_state, s_city)
)
SELECT
    d_year,
    i_brand,
    cc_state,
    s_city,
    total_sales,
    total_quantity,
    avg_discount,
    distinct_orders,
    ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY total_sales DESC) AS sales_rank
FROM agg
ORDER BY d_year, i_brand, cc_state, s_city
LIMIT 100
