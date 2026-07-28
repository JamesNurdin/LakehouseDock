WITH sales_agg AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        i.i_category,
        SUM(ss.ss_net_profit) AS total_net_profit,
        SUM(ss.ss_quantity) AS total_quantity,
        AVG(ss.ss_sales_price) AS avg_sales_price,
        SUM(cr.cr_return_amount) AS total_catalog_return_amount,
        SUM(wr.wr_return_amt) AS total_web_return_amount
    FROM store_sales ss
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN inventory inv ON i.i_item_sk = inv.inv_item_sk
    JOIN catalog_returns cr ON cr.cr_returned_time_sk = td.t_time_sk
        AND cr.cr_item_sk = i.i_item_sk
        AND cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
        AND cr.cr_refunded_addr_sk = ca.ca_address_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN web_returns wr ON wr.wr_returned_time_sk = td.t_time_sk
        AND wr.wr_item_sk = i.i_item_sk
        AND wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
        AND wr.wr_refunded_addr_sk = ca.ca_address_sk
    WHERE
        i.i_color = 'turquoise'
        AND i.i_formulation LIKE '%olive%'
        AND cp.cp_type = 'quarterly'
        AND cp.cp_catalog_page_number BETWEEN 5 AND 15
        AND cc.cc_state = 'CA'
        AND s.s_state = 'CA'
        AND p.p_discount_active = 'Y'
        AND i.i_current_price > 100
        AND inv.inv_quantity_on_hand > 0
        AND cc.cc_rec_start_date >= DATE '2000-01-01'
    GROUP BY
        s.s_store_id,
        s.s_store_name,
        i.i_category
    HAVING
        SUM(ss.ss_net_profit) > 10000
)
SELECT
    sa.s_store_id,
    sa.s_store_name,
    sa.i_category,
    sa.total_net_profit,
    sa.total_quantity,
    sa.avg_sales_price,
    sa.total_catalog_return_amount,
    sa.total_web_return_amount,
    RANK() OVER (ORDER BY sa.total_net_profit DESC) AS profit_rank,
    (SELECT AVG(total_net_profit) FROM sales_agg) AS avg_store_profit,
    CASE
        WHEN sa.total_net_profit > (SELECT AVG(total_net_profit) FROM sales_agg) * 1.5 THEN 'High'
        ELSE 'Normal'
    END AS profit_level
FROM sales_agg sa
ORDER BY sa.total_net_profit DESC
LIMIT 100
