WITH unified_sales AS (
    SELECT 
        cs_sold_date_sk AS sold_date_sk,
        cs_sold_time_sk AS sold_time_sk,
        cs_item_sk AS item_sk,
        cs_bill_customer_sk AS customer_sk,
        cs_promo_sk AS promo_sk,
        cs_order_number AS order_number,
        cs_net_paid_inc_tax AS net_paid_inc_tax,
        cs_net_profit AS net_profit,
        'catalog' AS channel,
        cs_call_center_sk AS call_center_sk,
        CAST(NULL AS integer) AS web_page_sk,
        CAST(NULL AS integer) AS store_sk
    FROM catalog_sales

    UNION ALL

    SELECT 
        ss_sold_date_sk,
        ss_sold_time_sk,
        ss_item_sk,
        ss_customer_sk,
        ss_promo_sk,
        ss_ticket_number,
        ss_net_paid_inc_tax,
        ss_net_profit,
        'store' AS channel,
        CAST(NULL AS integer),
        CAST(NULL AS integer),
        ss_store_sk
    FROM store_sales

    UNION ALL

    SELECT 
        ws_sold_date_sk,
        ws_sold_time_sk,
        ws_item_sk,
        ws_bill_customer_sk,
        ws_promo_sk,
        ws_order_number,
        ws_net_paid_inc_tax,
        ws_net_profit,
        'web' AS channel,
        CAST(NULL AS integer),
        ws_web_page_sk,
        CAST(NULL AS integer)
    FROM web_sales
),

customer_last_purchase AS (
    SELECT 
        c.c_customer_sk,
        MAX(d.d_date) AS last_purchase_date
    FROM customer c
    LEFT JOIN unified_sales us ON c.c_customer_sk = us.customer_sk
    LEFT JOIN date_dim d ON us.sold_date_sk = d.d_date_sk
    GROUP BY c.c_customer_sk
),

sales_with_details AS (
    SELECT 
        us.sold_date_sk,
        us.sold_time_sk,
        us.item_sk,
        us.customer_sk,
        us.promo_sk,
        us.order_number,
        us.net_paid_inc_tax,
        us.net_profit,
        us.channel,
        us.call_center_sk,
        us.web_page_sk,
        us.store_sk,
        d.d_date,
        i.i_product_name,
        i.i_category,
        i.i_brand,
        COALESCE(cc.cc_name, 'NO_CALL_CENTER') AS call_center_name,
        COALESCE(wp.wp_url, 'NO_WEBPAGE') AS webpage_url,
        COALESCE(s.s_store_name, 'NO_STORE') AS store_name,
        CASE 
            WHEN us.channel = 'catalog' AND p.p_discount_active = 'Y' THEN us.net_profit * 1.1
            WHEN us.channel = 'store' AND s.s_gmt_offset > 0 THEN us.net_profit * 0.9
            WHEN us.channel = 'web' AND us.promo_sk IS NOT NULL THEN us.net_profit * 1.05
            ELSE us.net_profit
        END AS adjusted_net_profit,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_name,
        ca.ca_state AS state
    FROM unified_sales us
    LEFT JOIN date_dim d ON us.sold_date_sk = d.d_date_sk
    LEFT JOIN item i ON us.item_sk = i.i_item_sk
    LEFT JOIN promotion p ON us.promo_sk = p.p_promo_sk
    LEFT JOIN call_center cc ON us.call_center_sk = cc.cc_call_center_sk
    LEFT JOIN web_page wp ON us.web_page_sk = wp.wp_web_page_sk
    LEFT JOIN store s ON us.store_sk = s.s_store_sk
    LEFT JOIN customer c ON us.customer_sk = c.c_customer_sk
    LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),

top_customers AS (
    SELECT 
        swd.customer_sk,
        swd.customer_name,
        swd.state,
        SUM(swd.adjusted_net_profit) AS total_adj_profit,
        COUNT(*) AS transaction_count
    FROM sales_with_details swd
    WHERE swd.adjusted_net_profit IS NOT NULL
    GROUP BY swd.customer_sk, swd.customer_name, swd.state
),

ranked_customers AS (
    SELECT 
        tc.*,
        ROW_NUMBER() OVER (PARTITION BY tc.state ORDER BY tc.total_adj_profit DESC) AS rank_in_state
    FROM top_customers tc
),

returns_union AS (
    SELECT 
        cr_returned_date_sk AS return_date_sk,
        cr_return_quantity AS return_quantity,
        cr_net_loss AS net_loss,
        'catalog' AS channel
    FROM catalog_returns

    UNION ALL

    SELECT 
        sr_returned_date_sk,
        sr_return_quantity,
        sr_net_loss,
        'store'
    FROM store_returns

    UNION ALL

    SELECT 
        wr_returned_date_sk,
        wr_return_quantity,
        wr_net_loss,
        'web'
    FROM web_returns
),

customer_returns AS (
    SELECT 
        us.customer_sk,
        SUM(r.return_quantity) FILTER (WHERE r.net_loss > 0) AS total_returns
    FROM sales_with_details us
    LEFT JOIN returns_union r 
        ON us.sold_date_sk = r.return_date_sk AND us.channel = r.channel
    GROUP BY us.customer_sk
),

final AS (
    SELECT 
        rc.customer_sk,
        rc.customer_name,
        rc.state,
        rc.total_adj_profit,
        rc.transaction_count,
        rc.rank_in_state,
        clp.last_purchase_date,
        COALESCE(cr.total_returns, 0) AS total_returns,
        CASE 
            WHEN COALESCE(cr.total_returns, 0) > 0 THEN rc.total_adj_profit / cr.total_returns
            ELSE NULL
        END AS profit_per_return_ratio,
        SUM(rc.total_adj_profit) OVER (PARTITION BY rc.state ORDER BY rc.rank_in_state ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cum_profit_by_state,
        (SELECT MAX(us_sub.net_paid_inc_tax) FROM unified_sales us_sub WHERE us_sub.customer_sk = rc.customer_sk) AS max_single_payment
    FROM ranked_customers rc
    LEFT JOIN customer_last_purchase clp ON rc.customer_sk = clp.c_customer_sk
    LEFT JOIN customer_returns cr ON rc.customer_sk = cr.customer_sk
    WHERE (rc.rank_in_state <= 5 OR rc.total_adj_profit > 10000)
      AND (rc.state LIKE 'C%' OR rc.state IS NULL)
)

SELECT *
FROM final
ORDER BY state, rank_in_state
LIMIT 100
