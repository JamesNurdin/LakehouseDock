WITH store_sales_agg AS (
    SELECT
        ss_store_sk,
        SUM(ss_net_paid_inc_tax) AS store_sales_net_paid,
        COUNT(*) AS store_sales_cnt
    FROM store_sales
    WHERE ss_item_sk IN (
        SELECT i_item_sk
        FROM item
        WHERE i_brand = 'BrandX'
    )
    GROUP BY ss_store_sk
),
joined_data AS (
    SELECT
        s.s_store_id,
        d_sold.d_year,
        i.i_category,
        ws.ws_net_paid_inc_tax,
        cr.cr_return_amount,
        ssagg.store_sales_net_paid,
        (SELECT SUM(ss2.ss_net_profit)
         FROM store_sales ss2
         WHERE ss2.ss_store_sk = s.s_store_sk) AS total_store_profit
    FROM store s
    JOIN store_sales ss ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d_sold ON ss.ss_sold_date_sk = d_sold.d_date_sk
    FULL OUTER JOIN web_sales ws
        ON ss.ss_item_sk = ws.ws_item_sk
       AND ss.ss_sold_date_sk = ws.ws_sold_date_sk
    LEFT JOIN item i ON ss.ss_item_sk = i.i_item_sk
    LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    LEFT JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    LEFT JOIN catalog_returns cr
        ON cr.cr_item_sk = i.i_item_sk
       AND cr.cr_returned_date_sk = d_sold.d_date_sk
    LEFT JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    LEFT JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    LEFT JOIN date_dim d_return ON cr.cr_returned_date_sk = d_return.d_date_sk
    LEFT JOIN store_sales_agg ssagg ON ssagg.ss_store_sk = s.s_store_sk
    WHERE s.s_store_sk IN (
        SELECT s2.s_store_sk FROM store s2
        EXCEPT
        SELECT s3.s_store_sk FROM store s3 WHERE s3.s_state = 'CA'
    )
)
SELECT
    s_store_id,
    d_year,
    i_category,
    SUM(ws_net_paid_inc_tax) AS total_web_net_paid,
    SUM(cr_return_amount) AS total_return_amount,
    SUM(store_sales_net_paid) AS total_store_sales_net_paid,
    MAX(total_store_profit) AS store_profit
FROM joined_data
GROUP BY s_store_id, d_year, i_category
ORDER BY total_web_net_paid DESC
LIMIT 100
