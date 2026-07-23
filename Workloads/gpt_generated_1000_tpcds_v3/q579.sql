WITH combined_sales AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        ca.ca_state,
        cd.cd_education_status,
        p.p_promo_id,
        td.t_hour,
        ss.ss_net_profit AS store_net_profit,
        ss.ss_ext_sales_price AS store_ext_sales_price,
        ss.ss_quantity AS store_quantity,
        sr.sr_net_loss AS store_return_loss,
        ws.ws_net_profit AS web_net_profit,
        ws.ws_ext_sales_price AS web_ext_sales_price,
        ws.ws_quantity AS web_quantity,
        wr.wr_net_loss AS web_return_loss,
        ws.ws_order_number,
        ws.ws_promo_sk
    FROM store_sales ss
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    LEFT JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
        AND sr.sr_item_sk = ss.ss_item_sk
    LEFT JOIN web_sales ws ON ws.ws_promo_sk = p.p_promo_sk
        AND ws.ws_sold_time_sk = td.t_time_sk
        AND ws.ws_bill_customer_sk = c.c_customer_sk
    LEFT JOIN web_site ws_site ON ws.ws_web_site_sk = ws_site.web_site_sk
    LEFT JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
        AND wr.wr_item_sk = ws.ws_item_sk
    WHERE
        c.c_birth_year BETWEEN 1950 AND 1970
        AND ca.ca_state IN ('CA', 'TX', 'NY')
        AND cd.cd_education_status = 'College'
        AND td.t_hour BETWEEN 9 AND 18
        AND ss.ss_ext_sales_price > 500
        AND p.p_discount_active = 'Y'
        AND sr.sr_fee > 20
        AND wr.wr_return_amt > 100
),
customer_agg AS (
    SELECT
        c_customer_sk,
        c_first_name,
        c_last_name,
        ca_state,
        SUM(store_net_profit) AS total_store_profit,
        SUM(store_ext_sales_price) AS total_store_sales,
        SUM(store_quantity) AS total_store_qty,
        SUM(COALESCE(store_return_loss, 0)) AS total_store_return_loss,
        SUM(web_net_profit) AS total_web_profit,
        SUM(web_ext_sales_price) AS total_web_sales,
        SUM(web_quantity) AS total_web_qty,
        SUM(COALESCE(web_return_loss, 0)) AS total_web_return_loss,
        COUNT(DISTINCT ws_order_number) AS web_orders,
        COUNT(*) AS total_transactions,
        AVG(store_ext_sales_price) AS avg_store_sales_amount
    FROM combined_sales
    GROUP BY c_customer_sk, c_first_name, c_last_name, ca_state
)
SELECT
    c_customer_sk,
    c_first_name,
    c_last_name,
    ca_state,
    total_store_profit,
    total_web_profit,
    total_store_sales,
    total_web_sales,
    total_store_return_loss,
    total_web_return_loss,
    total_transactions,
    avg_store_sales_amount,
    (total_store_profit + total_web_profit) AS total_combined_profit
FROM customer_agg
WHERE (total_store_profit + total_web_profit) > (
    SELECT AVG(total_store_profit + total_web_profit) FROM customer_agg
)
ORDER BY total_combined_profit DESC
LIMIT 100
