WITH sales_agg AS (
    SELECT
        COALESCE(s.s_state, 'UNKNOWN') AS state,
        i.i_category,
        td.t_hour,
        SUM(cs.cs_net_paid) AS total_sales,
        COUNT(DISTINCT cs.cs_order_number) AS order_cnt,
        AVG(cs.cs_coupon_amt) AS avg_coupon,
        SUM(COALESCE(sr.sr_return_amt, 0)) AS total_return_amt,
        MIN(p.p_discount_active) AS promo_active
    FROM catalog_sales cs
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    LEFT JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    LEFT JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk
        AND sr.sr_cdemo_sk = cd.cd_demo_sk
        AND sr.sr_return_time_sk = td.t_time_sk
    LEFT JOIN store s ON sr.sr_store_sk = s.s_store_sk
    WHERE
        i.i_category_id = 8
        AND sm.sm_type = 'AIR'
        AND td.t_hour BETWEEN 9 AND 17
    GROUP BY
        COALESCE(s.s_state, 'UNKNOWN'),
        i.i_category,
        td.t_hour
    HAVING
        SUM(cs.cs_net_paid) > 10000
)
SELECT
    state,
    i_category,
    t_hour,
    total_sales,
    order_cnt,
    avg_coupon,
    total_return_amt,
    promo_active,
    ROW_NUMBER() OVER (PARTITION BY state ORDER BY total_sales DESC) AS rank_state
FROM sales_agg
ORDER BY total_sales DESC
LIMIT 100
