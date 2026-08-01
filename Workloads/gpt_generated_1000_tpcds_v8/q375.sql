WITH ss_agg AS (
        SELECT ss_item_sk,
               ss_promo_sk,
               SUM(ss_ext_sales_price) AS sum_store_sales,
               COUNT(*)               AS cnt_store_sales,
               AVG(ss_net_profit)    AS avg_store_profit
        FROM tpcds.store_sales
        TABLESAMPLE BERNOULLI (10)   -- sample 10% of rows
        WHERE ss_quantity > 1
          AND ss_list_price > 20
        GROUP BY ss_item_sk, ss_promo_sk
    ),
    ws_agg AS (
        SELECT ws_item_sk,
               ws_promo_sk,
               SUM(ws_ext_sales_price)   AS sum_web_sales,
               COUNT(DISTINCT ws_web_page_sk) AS distinct_pages
        FROM tpcds.web_sales
        WHERE ws_quantity > 1
          AND ws_sales_price > 30
        GROUP BY ws_item_sk, ws_promo_sk
    ),
    joined AS (
        SELECT ss.ss_item_sk,
               ss.ss_promo_sk,
               i.i_item_id,
               i.i_product_name,
               i.i_brand,
               i.i_current_price,
               p.p_promo_name,
               p.p_channel_tv,
               p.p_discount_active,
               ca.ca_address_sk,
               ca.ca_city,
               ca.ca_state,
               sm.sm_type,
               wp.wp_type,
               ss_agg.sum_store_sales,
               ss_agg.cnt_store_sales,
               ss_agg.avg_store_profit,
               ws_agg.sum_web_sales,
               ws_agg.distinct_pages,
               i.i_item_sk
        FROM ss_agg
        JOIN tpcds.store_sales ss
          ON ss.ss_item_sk = ss_agg.ss_item_sk
         AND ss.ss_promo_sk = ss_agg.ss_promo_sk
        JOIN tpcds.item i
          ON i.i_item_sk = ss.ss_item_sk
        JOIN tpcds.promotion p
          ON p.p_promo_sk = ss.ss_promo_sk
        JOIN tpcds.customer_address ca
          ON ca.ca_address_sk = ss.ss_addr_sk
        JOIN tpcds.web_sales ws
          ON ws.ws_item_sk = i.i_item_sk
         AND ws.ws_promo_sk = p.p_promo_sk
        JOIN tpcds.ship_mode sm
          ON sm.sm_ship_mode_sk = ws.ws_ship_mode_sk
        JOIN tpcds.web_page wp
          ON wp.wp_web_page_sk = ws.ws_web_page_sk
        JOIN ws_agg
          ON ws_agg.ws_item_sk = ws.ws_item_sk
         AND ws_agg.ws_promo_sk = ws.ws_promo_sk
        WHERE i.i_current_price > 50
          AND ca.ca_state = 'CA'
          AND p.p_discount_active = 'Y'
          AND sm.sm_type = 'OVERNIGHT'
          AND EXISTS (
                SELECT 1
                FROM tpcds.web_sales ws_corr
                WHERE ws_corr.ws_item_sk = i.i_item_sk
                  AND ws_corr.ws_net_paid > 500
          )
    )
SELECT
    j.i_item_id,
    j.i_product_name,
    j.p_promo_name,
    j.sm_type,
    SUM(j.sum_store_sales)                     AS total_store_sales,
    SUM(j.sum_web_sales)                       AS total_web_sales,
    COUNT(DISTINCT j.ca_city)                  AS distinct_cities,
    COUNT(DISTINCT j.wp_type)                  AS distinct_page_types,
    CASE WHEN j.p_channel_tv = 'Y' THEN 'TV' ELSE 'Other' END AS promo_channel,
    ROW_NUMBER() OVER (PARTITION BY j.i_brand ORDER BY SUM(j.sum_store_sales) DESC) AS brand_rank,
    (
        SELECT MAX(ws3.ws_net_paid)
        FROM tpcds.web_sales ws3
        WHERE ws3.ws_item_sk = j.i_item_sk
          AND ws3.ws_net_paid > 200
    )                                          AS max_net_paid_item
FROM joined j
GROUP BY
    j.i_item_id,
    j.i_product_name,
    j.p_promo_name,
    j.sm_type,
    j.p_channel_tv,
    j.i_brand,
    j.i_item_sk
ORDER BY total_store_sales DESC, j.i_item_id
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
