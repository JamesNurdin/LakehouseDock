WITH agg_data AS (
    SELECT
        ss.ss_customer_sk,
        c.c_first_name,
        c.c_last_name,
        i.i_item_id,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit,
        COUNT(DISTINCT ss.ss_ticket_number) AS num_transactions,
        SUM(cr.cr_return_amount) AS total_catalog_return,
        SUM(wr.wr_return_amt) AS total_web_return
    FROM store_sales ss
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    LEFT JOIN catalog_returns cr ON cr.cr_refunded_customer_sk = c.c_customer_sk
    LEFT JOIN web_returns wr ON wr.wr_refunded_customer_sk = c.c_customer_sk
    LEFT JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE
        i.i_current_price > 100
        AND p.p_discount_active = 'Y'
        AND td.t_hour BETWEEN 9 AND 17
        AND ss.ss_quantity > 1
        AND cd.cd_education_status = 'College'
        AND ca.ca_country = 'United States'
    GROUP BY
        ss.ss_customer_sk,
        c.c_first_name,
        c.c_last_name,
        i.i_item_id
    HAVING
        SUM(ss.ss_ext_sales_price) > 5000
)
SELECT
    ss_customer_sk,
    c_first_name,
    c_last_name,
    i_item_id,
    total_sales,
    total_profit,
    total_catalog_return,
    total_web_return,
    (total_sales - (total_catalog_return + total_web_return)) AS net_sales_after_returns,
    CASE WHEN total_profit > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_status
FROM agg_data
WHERE (total_sales - (total_catalog_return + total_web_return)) > 1000
ORDER BY net_sales_after_returns DESC
LIMIT 100
