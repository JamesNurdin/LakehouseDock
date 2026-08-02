WITH sales AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_item_sk,
        cs.cs_warehouse_sk,
        cs.cs_call_center_sk,
        cs.cs_catalog_page_sk,
        cs.cs_quantity,
        cs.cs_sales_price,
        cs.cs_ext_sales_price,
        cs.cs_net_profit,
        cs.cs_sold_time_sk,
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        hd.hd_income_band_sk,
        i.i_brand,
        i.i_category,
        i.i_product_name,
        w.w_warehouse_name,
        cc.cc_name,
        cp.cp_catalog_number,
        t.t_hour,
        inv.inv_quantity_on_hand
    FROM catalog_sales cs
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk AND inv.inv_warehouse_sk = w.w_warehouse_sk
    WHERE
        cs.cs_quantity > 2
        AND cs.cs_sales_price > 50
        AND cs.cs_net_profit > -100
        AND cc.cc_gmt_offset > -5
        AND cp.cp_catalog_number IN (3, 11, 14)
        AND i.i_brand_id IN (1, 2, 3)
        AND t.t_hour BETWEEN 8 AND 20
        AND inv.inv_quantity_on_hand > 0
),
returns AS (
    SELECT
        sr.sr_returned_date_sk,
        sr.sr_item_sk,
        sr.sr_store_sk,
        sr.sr_return_quantity,
        sr.sr_net_loss,
        sr.sr_return_time_sk,
        s.s_store_name,
        s.s_state,
        i.i_category,
        t.t_hour AS return_hour
    FROM store_returns sr
    JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    WHERE
        sr.sr_return_quantity > 0
        AND sr.sr_net_loss > 0
        AND s.s_state = 'CA'
        AND i.i_category_id IN (5, 7, 10)
        AND t.t_hour BETWEEN 9 AND 18
        AND sr.sr_returned_date_sk BETWEEN 2450000 AND 2452000
),
web_ret AS (
    SELECT
        wr.wr_returned_date_sk,
        wr.wr_item_sk,
        wr.wr_refunded_customer_sk,
        wr.wr_return_quantity,
        wr.wr_net_loss,
        wr.wr_returned_time_sk,
        wp.wp_web_page_id,
        wp.wp_url,
        c.c_first_name,
        c.c_last_name,
        i.i_category,
        i.i_color,
        t.t_hour AS web_return_hour
    FROM web_returns wr
    JOIN time_dim t ON wr.wr_returned_time_sk = t.t_time_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN customer c ON wr.wr_refunded_customer_sk = c.c_customer_sk
    WHERE
        wr.wr_return_quantity > 0
        AND wr.wr_net_loss > 0
        AND wp.wp_max_ad_count >= 2
        AND i.i_color = 'Red'
        AND t.t_hour BETWEEN 10 AND 22
        AND wr.wr_returned_date_sk BETWEEN 2450000 AND 2452000
),
intersect_items AS (
    SELECT cs_item_sk AS item_sk FROM sales
    INTERSECT
    SELECT sr_item_sk AS item_sk FROM returns
),
aggregated AS (
    SELECT
        i.i_item_sk,
        i.i_product_name,
        i.i_category,
        i.i_brand,
        s.s_store_name,
        s.s_state,
        cc.cc_name AS call_center_name,
        SUM(cs.cs_quantity) AS total_quantity_sold,
        SUM(cs.cs_net_profit) AS total_net_profit,
        SUM(sr.sr_return_quantity) AS total_quantity_returned,
        SUM(sr.sr_net_loss) AS total_net_loss,
        SUM(wr.wr_return_quantity) AS total_web_return_quantity,
        SUM(wr.wr_net_loss) AS total_web_net_loss,
        CASE
            WHEN SUM(cs.cs_net_profit) - (SUM(sr.sr_net_loss) + SUM(wr.wr_net_loss)) > 0 THEN 'Overall Profit'
            ELSE 'Overall Loss'
        END AS overall_status
    FROM intersect_items ii
    JOIN item i ON ii.item_sk = i.i_item_sk
    LEFT JOIN sales cs ON i.i_item_sk = cs.cs_item_sk
    LEFT JOIN returns sr ON i.i_item_sk = sr.sr_item_sk
    LEFT JOIN store s ON sr.sr_store_sk = s.s_store_sk
    LEFT JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    LEFT JOIN web_ret wr ON i.i_item_sk = wr.wr_item_sk
    GROUP BY
        i.i_item_sk,
        i.i_product_name,
        i.i_category,
        i.i_brand,
        s.s_store_name,
        s.s_state,
        cc.cc_name
    HAVING
        SUM(cs.cs_quantity) > 10
        AND SUM(sr.sr_return_quantity) > 0
        AND SUM(wr.wr_return_quantity) > 0
        AND (SUM(cs.cs_net_profit) - (SUM(sr.sr_net_loss) + SUM(wr.wr_net_loss))) IS NOT NULL
),
ranked AS (
    SELECT
        a.*,
        ROW_NUMBER() OVER (PARTITION BY a.i_category ORDER BY a.total_net_profit DESC) AS prod_rank_in_category,
        RANK() OVER (ORDER BY a.total_net_profit - (a.total_net_loss + a.total_web_net_loss) DESC) AS overall_rank
    FROM aggregated a
)
SELECT
    r.i_item_sk,
    r.i_product_name,
    r.i_category,
    r.i_brand,
    r.s_store_name,
    r.s_state,
    r.call_center_name,
    r.total_quantity_sold,
    r.total_quantity_returned,
    r.total_net_profit,
    r.total_net_loss,
    r.total_web_return_quantity,
    r.total_web_net_loss,
    r.overall_status,
    r.prod_rank_in_category,
    r.overall_rank
FROM ranked r
ORDER BY r.overall_rank
LIMIT 100
