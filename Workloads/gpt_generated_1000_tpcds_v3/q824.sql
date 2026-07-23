WITH base_sales AS (
    SELECT
        td.t_time_sk,
        td.t_hour,
        cs.cs_order_number,
        cs.cs_quantity,
        cs.cs_net_paid,
        cs.cs_net_profit,
        cp.cp_department,
        sm.sm_type,
        i.i_item_id,
        i.i_product_name,
        i.i_brand,
        i.i_category,
        sr.sr_return_quantity,
        sr.sr_return_amt,
        r.r_reason_desc,
        ws.ws_net_paid_inc_tax,
        ws.ws_ext_wholesale_cost,
        wp.wp_url,
        wr.wr_return_quantity,
        wr.wr_return_amt,
        wr.wr_account_credit
    FROM tpcds.time_dim td
    JOIN tpcds.catalog_sales cs ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN tpcds.ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN tpcds.catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN tpcds.item i ON cs.cs_item_sk = i.i_item_sk
    LEFT JOIN tpcds.store_returns sr ON i.i_item_sk = sr.sr_item_sk
    LEFT JOIN tpcds.reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN tpcds.web_sales ws ON i.i_item_sk = ws.ws_item_sk
    JOIN tpcds.web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN tpcds.web_returns wr ON ws.ws_order_number = wr.wr_order_number
    WHERE td.t_hour BETWEEN 9 AND 17
      AND cs.cs_quantity > 1
      AND ws.ws_ext_wholesale_cost > 1000
),
ranked_sales AS (
    SELECT
        *,
        ROW_NUMBER() OVER (PARTITION BY i_item_id ORDER BY cs_net_paid DESC) AS rn_item_sales,
        RANK() OVER (ORDER BY cs_net_profit DESC) AS rank_profit,
        CASE
            WHEN cs_net_profit > 1000 THEN 'High Profit'
            WHEN cs_net_profit BETWEEN 0 AND 1000 THEN 'Medium Profit'
            ELSE 'Low/Negative Profit'
        END AS profit_category
    FROM base_sales
)
SELECT
    t_time_sk,
    t_hour,
    cs_order_number,
    i_item_id,
    i_product_name,
    cp_department,
    sm_type,
    cs_quantity,
    cs_net_paid,
    cs_net_profit,
    sr_return_quantity,
    sr_return_amt,
    r_reason_desc,
    ws_net_paid_inc_tax,
    ws_ext_wholesale_cost,
    wp_url,
    wr_return_quantity,
    wr_return_amt,
    wr_account_credit,
    rn_item_sales,
    rank_profit,
    profit_category
FROM ranked_sales
WHERE rn_item_sales <= 5
ORDER BY cs_net_profit DESC
LIMIT 100
