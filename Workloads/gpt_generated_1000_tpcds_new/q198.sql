WITH base AS (
    SELECT
        cs.cs_order_number,
        cs.cs_ext_sales_price,
        cs.cs_net_profit,
        cc.cc_call_center_id,
        i.i_item_id,
        i.i_brand,
        ib.ib_lower_bound,
        hd_bill.hd_buy_potential
    FROM catalog_sales cs
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN customer_demographics cd_bill ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
    JOIN household_demographics hd_bill ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN income_band ib ON hd_bill.hd_income_band_sk = ib.ib_income_band_sk
    JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
    JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN time_dim td_ret ON wr.wr_returned_time_sk = td_ret.t_time_sk
    JOIN customer_demographics cd_refunded ON wr.wr_refunded_cdemo_sk = cd_refunded.cd_demo_sk
    JOIN household_demographics hd_refunded ON wr.wr_refunded_hdemo_sk = hd_refunded.hd_demo_sk
    WHERE cs.cs_order_number NOT IN (
        SELECT wr2.wr_order_number
        FROM web_returns wr2
        WHERE wr2.wr_return_quantity > 0
    )
)
,
agg_a AS (
    SELECT
        cc_call_center_id,
        i_item_id,
        i_brand,
        SUM(cs_ext_sales_price) AS total_sales,
        AVG(cs_net_profit) AS avg_profit,
        COUNT(DISTINCT cs_order_number) AS order_cnt
    FROM base
    WHERE ib_lower_bound >= 30000
    GROUP BY cc_call_center_id, i_item_id, i_brand
),
agg_b AS (
    SELECT
        cc_call_center_id,
        i_item_id,
        i_brand,
        SUM(cs_ext_sales_price) AS total_sales,
        AVG(cs_net_profit) AS avg_profit,
        COUNT(DISTINCT cs_order_number) AS order_cnt
    FROM base
    WHERE hd_buy_potential LIKE '1001-5000%'
    GROUP BY cc_call_center_id, i_item_id, i_brand
),
unioned AS (
    SELECT * FROM agg_a
    UNION
    SELECT * FROM agg_b
)
SELECT
    cc_call_center_id,
    i_item_id,
    i_brand,
    total_sales,
    avg_profit,
    order_cnt,
    ROW_NUMBER() OVER (PARTITION BY cc_call_center_id ORDER BY total_sales DESC) AS rn
FROM unioned
ORDER BY total_sales DESC
LIMIT 100
