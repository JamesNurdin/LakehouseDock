/* Goal: Summarize California store performance for 2001 by store and promotion, aggregating sales, returns, web profit, distinct catalog pages, and adjusting profit for TV promotions. */
WITH distinct_promos AS (
    SELECT DISTINCT p.p_promo_sk,
                    p.p_promo_id,
                    p.p_channel_tv
    FROM promotion p
    WHERE p.p_discount_active = 'Y'
),
joined_data AS (
    SELECT
        s.s_store_id,
        dp.p_promo_id,
        d_sales.d_year AS sales_year,
        ss.ss_ext_sales_price,
        ss.ss_net_profit,
        sr.sr_net_loss AS sr_net_loss,
        sr.sr_return_amt_inc_tax,
        cp.cp_catalog_page_id,
        ws.ws_net_profit AS web_net_profit,
        w.w_warehouse_name,
        cd.cd_gender,
        cd.cd_marital_status,
        CASE WHEN dp.p_channel_tv = 'Y' THEN ss.ss_net_profit * 1.1 ELSE ss.ss_net_profit END AS tv_adjusted_profit
    FROM store_sales ss
    INNER JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    INNER JOIN date_dim d_sales
        ON ss.ss_sold_date_sk = d_sales.d_date_sk
    INNER JOIN distinct_promos dp
        ON ss.ss_promo_sk = dp.p_promo_sk
    LEFT JOIN store_returns sr
        ON ss.ss_ticket_number = sr.sr_ticket_number
        AND ss.ss_item_sk = sr.sr_item_sk
    LEFT JOIN date_dim d_return
        ON sr.sr_returned_date_sk = d_return.d_date_sk
    LEFT JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN catalog_page cp
        ON cp.cp_start_date_sk = d_sales.d_date_sk
    LEFT JOIN web_sales ws
        ON ws.ws_promo_sk = dp.p_promo_sk
        AND ws.ws_sold_date_sk = d_sales.d_date_sk
    LEFT JOIN warehouse w
        ON ws.ws_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN date_dim d_ws_ship
        ON ws.ws_ship_date_sk = d_ws_ship.d_date_sk
    LEFT JOIN date_dim d_cp_end
        ON cp.cp_end_date_sk = d_cp_end.d_date_sk
    LEFT JOIN promotion p_start
        ON p_start.p_start_date_sk = d_sales.d_date_sk
    LEFT JOIN promotion p_end
        ON p_end.p_end_date_sk = d_return.d_date_sk
    WHERE s.s_state = 'CA'
)
SELECT
    s_store_id,
    p_promo_id,
    sales_year,
    SUM(ss_ext_sales_price) AS total_sales_amount,
    SUM(sr_net_loss) AS total_return_loss,
    SUM(tv_adjusted_profit) AS total_tv_adjusted_profit,
    COUNT(DISTINCT cp_catalog_page_id) AS distinct_catalog_pages,
    SUM(web_net_profit) AS total_web_net_profit
FROM joined_data
GROUP BY s_store_id, p_promo_id, sales_year
ORDER BY total_tv_adjusted_profit DESC
LIMIT 100
