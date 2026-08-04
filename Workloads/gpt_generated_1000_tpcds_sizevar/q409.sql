WITH item_exp AS (
    SELECT i.i_item_sk,
           i.i_brand,
           i.i_category,
           i.i_size,
           attr
    FROM tpcds.item i
    CROSS JOIN UNNEST(ARRAY[i.i_brand, i.i_category]) AS t(attr)
),
catalog_sales_join AS (
    SELECT cs.cs_sold_time_sk,
           cs.cs_item_sk,
           cs.cs_bill_customer_sk,
           cs.cs_call_center_sk,
           cs.cs_warehouse_sk,
           cs.cs_promo_sk,
           cs.cs_net_paid,
           cc.cc_name,
           cc.cc_call_center_sk
    FROM tpcds.catalog_sales cs
    JOIN tpcds.call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
),
inventory_ware AS (
    SELECT inv.inv_item_sk,
           inv.inv_quantity_on_hand,
           w.w_warehouse_sk,
           w.w_state,
           w.w_warehouse_name
    FROM tpcds.inventory inv TABLESAMPLE BERNOULLI (10)
    JOIN tpcds.warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
),
combined_sales_returns AS (
    SELECT
        ss.ss_store_sk,
        ss.ss_sold_time_sk,
        ss.ss_item_sk,
        ss.ss_quantity,
        ss.ss_net_paid,
        ss.ss_cdemo_sk,
        ss.ss_hdemo_sk,
        ss.ss_customer_sk,
        ss.ss_promo_sk,
        ss.ss_ticket_number,
        sr.sr_store_sk,
        sr.sr_return_time_sk,
        sr.sr_item_sk,
        sr.sr_return_amt,
        sr.sr_reason_sk,
        sr.sr_customer_sk,
        sr.sr_cdemo_sk,
        sr.sr_hdemo_sk
    FROM tpcds.store_sales ss
    FULL OUTER JOIN tpcds.store_returns sr
      ON ss.ss_ticket_number = sr.sr_ticket_number
),
sales_agg AS (
    SELECT
        COALESCE(cs.ss_store_sk, cs.sr_store_sk)                              AS store_sk,
        s.s_store_name,
        td.t_meal_time,
        SUM(COALESCE(cs.ss_net_paid, 0) - COALESCE(cs.sr_return_amt, 0))   AS net_sales,
        COUNT(*)                                                            AS trans_cnt,
        COUNT(DISTINCT wp.wp_web_page_sk)                                   AS web_page_cnt,
        COUNT(DISTINCT r.r_reason_sk)                                       AS return_reason_cnt,
        COUNT(DISTINCT cc.cc_call_center_sk)                                 AS call_center_cnt
    FROM combined_sales_returns cs
    JOIN tpcds.time_dim td ON (
            cs.ss_sold_time_sk = td.t_time_sk OR
            cs.sr_return_time_sk = td.t_time_sk)
    JOIN item_exp i ON COALESCE(cs.ss_item_sk, cs.sr_item_sk) = i.i_item_sk
    JOIN tpcds.customer c ON COALESCE(cs.ss_customer_sk, cs.sr_customer_sk) = c.c_customer_sk
    JOIN tpcds.store s ON COALESCE(cs.ss_store_sk, cs.sr_store_sk) = s.s_store_sk
    LEFT JOIN tpcds.customer_demographics cd ON cs.ss_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN tpcds.household_demographics hd ON cs.ss_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN tpcds.web_page wp ON c.c_customer_sk = wp.wp_customer_sk
    LEFT JOIN tpcds.reason r ON cs.sr_reason_sk = r.r_reason_sk
    LEFT JOIN catalog_sales_join csj ON csj.cs_bill_customer_sk = c.c_customer_sk
    LEFT JOIN tpcds.call_center cc ON csj.cs_call_center_sk = cc.cc_call_center_sk
    LEFT JOIN tpcds.promotion p ON cs.ss_promo_sk = p.p_promo_sk
    WHERE td.t_meal_time = 'dinner'
      AND i.i_size = 'large'
      AND c.c_birth_day = 13
      AND p.p_discount_active = 'Y'
    GROUP BY COALESCE(cs.ss_store_sk, cs.sr_store_sk), s.s_store_name, td.t_meal_time
)
SELECT
    sa.s_store_name,
    sa.t_meal_time,
    sa.net_sales,
    sa.trans_cnt,
    ROUND(sa.net_sales / NULLIF(sa.trans_cnt, 0), 2) AS avg_net_per_trans,
    sa.web_page_cnt,
    sa.return_reason_cnt,
    sa.call_center_cnt,
    w.w_state,
    w.w_warehouse_name
FROM sales_agg sa
LEFT JOIN inventory_ware w ON sa.store_sk = w.w_warehouse_sk
ORDER BY sa.net_sales DESC
LIMIT 100
