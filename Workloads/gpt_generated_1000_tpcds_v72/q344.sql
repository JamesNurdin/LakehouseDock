WITH base AS (
    SELECT
        cc.cc_call_center_id AS call_center_id,
        i.i_category AS category,
        td.t_sub_shift AS sub_shift,
        hd_bill.hd_income_band_sk AS income_band,
        cs.cs_net_profit AS net_profit,
        COALESCE(cr.cr_net_loss, 0) AS catalog_return_loss,
        COALESCE(wr.wr_net_loss, 0) AS web_return_loss,
        p.p_cost AS promo_cost,
        CASE WHEN cs.cs_net_profit > 0 THEN 'Profit' ELSE 'Loss' END AS profit_flag,
        (SELECT AVG(p2.p_cost) FROM promotion p2 WHERE p2.p_item_sk = i.i_item_sk) AS avg_item_promo_cost
    FROM catalog_sales cs
    JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN household_demographics hd_bill ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN customer c_bill ON cs.cs_bill_customer_sk = c_bill.c_customer_sk
    JOIN household_demographics hd_ship ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
    JOIN customer_address ca_bill ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
    JOIN customer_address ca_ship ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
    LEFT JOIN catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
        AND cr.cr_item_sk = cs.cs_item_sk
    LEFT JOIN customer c_refund ON cr.cr_refunded_customer_sk = c_refund.c_customer_sk
    LEFT JOIN household_demographics hd_refund ON cr.cr_refunded_hdemo_sk = hd_refund.hd_demo_sk
    LEFT JOIN customer_address ca_refund ON cr.cr_refunded_addr_sk = ca_refund.ca_address_sk
    LEFT JOIN customer c_return ON cr.cr_returning_customer_sk = c_return.c_customer_sk
    LEFT JOIN household_demographics hd_return ON cr.cr_returning_hdemo_sk = hd_return.hd_demo_sk
    LEFT JOIN customer_address ca_return ON cr.cr_returning_addr_sk = ca_return.ca_address_sk
    LEFT JOIN call_center cc_ret ON cr.cr_call_center_sk = cc_ret.cc_call_center_sk
    LEFT JOIN web_returns wr
        ON wr.wr_item_sk = i.i_item_sk
        AND wr.wr_returned_time_sk = td.t_time_sk
    LEFT JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN customer c_web ON wp.wp_customer_sk = c_web.c_customer_sk
    LEFT JOIN household_demographics hd_web_refund ON wr.wr_refunded_hdemo_sk = hd_web_refund.hd_demo_sk
    LEFT JOIN customer_address ca_web_refund ON wr.wr_refunded_addr_sk = ca_web_refund.ca_address_sk
    LEFT JOIN household_demographics hd_web_return ON wr.wr_returning_hdemo_sk = hd_web_return.hd_demo_sk
    LEFT JOIN customer_address ca_web_return ON wr.wr_returning_addr_sk = ca_web_return.ca_address_sk
    WHERE
        cc.cc_call_center_id IN ('CC_1', 'CC_13', 'CC_31')
        AND td.t_sub_shift IN ('morning', 'afternoon')
        AND hd_bill.hd_income_band_sk IN (11, 12, 13)
        AND i.i_current_price > 100
),
agg AS (
    SELECT
        call_center_id,
        category,
        sub_shift,
        income_band,
        profit_flag,
        SUM(net_profit) AS total_net_profit,
        SUM(catalog_return_loss + web_return_loss) AS total_net_loss,
        AVG(avg_item_promo_cost) AS avg_promo_cost
    FROM base
    GROUP BY GROUPING SETS (
        (call_center_id, category, sub_shift, income_band, profit_flag),
        (call_center_id, category, sub_shift, income_band),
        (call_center_id, category, sub_shift),
        (call_center_id, category),
        (call_center_id),
        ()
    )
)
SELECT
    a.call_center_id,
    a.category,
    a.sub_shift,
    a.income_band,
    a.profit_flag,
    a.total_net_profit,
    a.total_net_loss,
    a.avg_promo_cost,
    (
        SELECT AVG(b.total_net_profit)
        FROM agg b
        WHERE b.call_center_id = a.call_center_id
    ) AS avg_profit_per_call_center
FROM agg a
ORDER BY
    a.call_center_id,
    a.category,
    a.sub_shift,
    a.income_band,
    a.profit_flag
LIMIT 100
