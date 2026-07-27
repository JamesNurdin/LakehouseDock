WITH
    store_sales_agg AS (
        SELECT
            ss_store_sk,
            ss_promo_sk,
            ss_sold_time_sk,
            ss_cdemo_sk,
            ss_addr_sk,
            SUM(ss_ext_sales_price) AS store_sales_total,
            SUM(ss_net_profit) AS store_profit,
            COUNT(*) AS store_txn_cnt
        FROM store_sales
        WHERE ss_quantity > 1
          AND ss_ext_sales_price > 0
        GROUP BY ss_store_sk, ss_promo_sk, ss_sold_time_sk, ss_cdemo_sk, ss_addr_sk
    ),
    web_sales_agg AS (
        SELECT
            ws_web_page_sk,
            ws_promo_sk,
            ws_sold_time_sk,
            ws_order_number,
            SUM(ws_ext_sales_price) AS web_sales_total,
            SUM(ws_net_profit) AS web_profit,
            COUNT(*) AS web_txn_cnt
        FROM web_sales
        WHERE ws_quantity > 0
          AND ws_ext_sales_price > 0
        GROUP BY ws_web_page_sk, ws_promo_sk, ws_sold_time_sk, ws_order_number
    )
SELECT
    s.s_store_name,
    s.s_state,
    p.p_promo_name,
    t.t_hour,
    ca.ca_city,
    cd.cd_education_status,
    store_sales_agg.store_sales_total,
    store_sales_agg.store_profit,
    web_sales_agg.web_sales_total,
    web_sales_agg.web_profit,
    SUM(wr.wr_net_loss) AS total_return_loss,
    CASE
        WHEN store_sales_agg.store_profit > 10000 THEN 'High Profit'
        WHEN store_sales_agg.store_profit BETWEEN 0 AND 10000 THEN 'Medium Profit'
        ELSE 'Low Profit'
    END AS profit_category
FROM store_sales_agg
JOIN store s
    ON store_sales_agg.ss_store_sk = s.s_store_sk
JOIN promotion p
    ON store_sales_agg.ss_promo_sk = p.p_promo_sk
JOIN time_dim t
    ON store_sales_agg.ss_sold_time_sk = t.t_time_sk
JOIN customer_address ca
    ON store_sales_agg.ss_addr_sk = ca.ca_address_sk
JOIN customer_demographics cd
    ON store_sales_agg.ss_cdemo_sk = cd.cd_demo_sk
JOIN web_sales_agg
    ON store_sales_agg.ss_promo_sk = web_sales_agg.ws_promo_sk
   AND store_sales_agg.ss_sold_time_sk = web_sales_agg.ws_sold_time_sk
JOIN web_page wp
    ON web_sales_agg.ws_web_page_sk = wp.wp_web_page_sk
JOIN web_returns wr
    ON web_sales_agg.ws_order_number = wr.wr_order_number
   AND wr.wr_returned_time_sk = t.t_time_sk
WHERE s.s_state = 'CA'
  AND p.p_discount_active = 'Y'
  AND t.t_hour BETWEEN 9 AND 17
  AND cd.cd_education_status = 'College'
  AND s.s_floor_space > 5000000
  AND ca.ca_country = 'United States'
GROUP BY
    s.s_store_name,
    s.s_state,
    p.p_promo_name,
    t.t_hour,
    ca.ca_city,
    cd.cd_education_status,
    store_sales_agg.store_sales_total,
    store_sales_agg.store_profit,
    web_sales_agg.web_sales_total,
    web_sales_agg.web_profit,
    CASE
        WHEN store_sales_agg.store_profit > 10000 THEN 'High Profit'
        WHEN store_sales_agg.store_profit BETWEEN 0 AND 10000 THEN 'Medium Profit'
        ELSE 'Low Profit'
    END
ORDER BY store_sales_agg.store_sales_total DESC
LIMIT 100
