WITH base AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_sold_time_sk,
        cs.cs_ship_date_sk,
        cs.cs_bill_customer_sk,
        cs.cs_bill_cdemo_sk,
        cs.cs_bill_hdemo_sk,
        cs.cs_bill_addr_sk,
        cs.cs_ship_customer_sk,
        cs.cs_ship_cdemo_sk,
        cs.cs_ship_hdemo_sk,
        cs.cs_ship_addr_sk,
        cs.cs_catalog_page_sk,
        cs.cs_ship_mode_sk,
        cs.cs_warehouse_sk,
        cs.cs_item_sk,
        cs.cs_promo_sk,
        cs.cs_quantity,
        cs.cs_net_profit,
        cs.cs_ext_sales_price,
        cs.cs_ext_discount_amt,
        cs.cs_order_number
    FROM catalog_sales cs
)
SELECT
    d.d_year,
    i.i_category,
    i.i_item_id,
    c.c_customer_id,
    ca.ca_state,
    hd.hd_income_band_sk,
    p.p_promo_name,
    sm.sm_type,
    w.w_warehouse_name,
    wp.wp_type,
    r.r_reason_desc,
    cs.cs_quantity,
    cs.cs_net_profit,
    SUM(cs.cs_net_profit) OVER (PARTITION BY i.i_category ORDER BY cs.cs_net_profit DESC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cum_profit,
    ROW_NUMBER() OVER (PARTITION BY i.i_category ORDER BY cs.cs_net_profit DESC) AS rn_category,
    RANK() OVER (ORDER BY cs.cs_net_profit DESC) AS overall_rank
FROM base cs
JOIN catalog_page cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN date_dim d
    ON cs.cs_sold_date_sk = d.d_date_sk
JOIN time_dim t
    ON cs.cs_sold_time_sk = t.t_time_sk
JOIN warehouse w
    ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN ship_mode sm
    ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN item i
    ON cs.cs_item_sk = i.i_item_sk
JOIN promotion p
    ON cs.cs_promo_sk = p.p_promo_sk
JOIN customer c
    ON cs.cs_bill_customer_sk = c.c_customer_sk
JOIN customer_address ca
    ON cs.cs_bill_addr_sk = ca.ca_address_sk
JOIN customer_demographics cd
    ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd
    ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
JOIN web_returns wr
    ON wr.wr_item_sk = cs.cs_item_sk
JOIN reason r
    ON wr.wr_reason_sk = r.r_reason_sk
JOIN web_page wp
    ON wr.wr_web_page_sk = wp.wp_web_page_sk
JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
WHERE d.d_year = 2001
  AND i.i_category = 'Sports'
  AND p.p_discount_active = 'Y'
  AND cd.cd_gender = 'M'
  AND w.w_county = 'Richland County'
  AND cs.cs_quantity > 2
ORDER BY overall_rank
LIMIT 100
