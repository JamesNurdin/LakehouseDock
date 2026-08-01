WITH joined_data AS (
    SELECT
        ss.ss_ticket_number,
        ss.ss_sold_date_sk,
        ss.ss_quantity AS store_quantity,
        ss.ss_ext_sales_price AS store_ext_sales_price,
        ss.ss_net_profit AS store_net_profit,
        ss.ss_promo_sk AS store_promo_sk,
        ca.ca_state,
        ca.ca_country,
        cd.cd_gender,
        cd.cd_demo_sk,
        d.d_year,
        d.d_month_seq,
        d.d_date,
        p_store.p_promo_name AS store_promo_name,
        p_store.p_discount_active AS store_promo_discount,
        p_store.p_cost AS store_promo_cost,
        sr.sr_return_quantity,
        sr.sr_net_loss AS store_return_net_loss,
        ws.ws_order_number,
        ws.ws_quantity AS web_quantity,
        ws.ws_ext_sales_price AS web_ext_sales_price,
        ws.ws_net_profit AS web_net_profit,
        ws.ws_promo_sk AS web_promo_sk,
        ws.ws_warehouse_sk,
        ws.ws_web_page_sk,
        ws.ws_web_site_sk,
        p_web.p_promo_name AS web_promo_name,
        p_web.p_discount_active AS web_promo_discount,
        w.w_warehouse_name,
        web_site.web_name AS website_name,
        wr.wr_return_quantity,
        wr.wr_net_loss AS web_return_net_loss,
        wp_lateral.wp_url,
        wp_lateral.wp_type
    FROM store_sales ss
    JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN promotion p_store
        ON ss.ss_promo_sk = p_store.p_promo_sk
    LEFT JOIN store_returns sr
        ON sr.sr_ticket_number = ss.ss_ticket_number
        AND sr.sr_item_sk = ss.ss_item_sk
        AND sr.sr_cdemo_sk = cd.cd_demo_sk
        AND sr.sr_addr_sk = ca.ca_address_sk
        AND sr.sr_returned_date_sk = d.d_date_sk
    LEFT JOIN web_sales ws
        ON ws.ws_sold_date_sk = d.d_date_sk
        AND ws.ws_bill_cdemo_sk = cd.cd_demo_sk
        AND ws.ws_bill_addr_sk = ca.ca_address_sk
        AND ws.ws_promo_sk = p_store.p_promo_sk
    LEFT JOIN warehouse w
        ON ws.ws_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN web_site
        ON ws.ws_web_site_sk = web_site.web_site_sk
    LEFT JOIN promotion p_web
        ON ws.ws_promo_sk = p_web.p_promo_sk
    LEFT JOIN web_returns wr
        ON wr.wr_order_number = ws.ws_order_number
        AND wr.wr_item_sk = ws.ws_item_sk
        AND wr.wr_returned_date_sk = d.d_date_sk
        AND wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
        AND wr.wr_refunded_addr_sk = ca.ca_address_sk
    CROSS JOIN LATERAL (
        SELECT wp.wp_url, wp.wp_type
        FROM web_page wp
        WHERE wp.wp_web_page_sk = ws.ws_web_page_sk
        LIMIT 1
    ) wp_lateral
)
SELECT
    jd.d_year,
    jd.d_month_seq,
    jd.store_promo_name,
    SUM(jd.store_ext_sales_price) AS total_store_sales,
    SUM(jd.web_ext_sales_price) AS total_web_sales,
    SUM(jd.store_net_profit) + SUM(jd.web_net_profit) AS total_net_profit,
    RANK() OVER (PARTITION BY jd.d_year ORDER BY SUM(jd.store_net_profit) + SUM(jd.web_net_profit) DESC) AS profit_rank_year,
    CASE
        WHEN SUM(jd.store_net_profit) + SUM(jd.web_net_profit) > 0 THEN 'POSITIVE'
        ELSE 'NON_POSITIVE'
    END AS profit_status,
    (SELECT COUNT(DISTINCT p2.p_promo_sk) FROM promotion p2 WHERE p2.p_discount_active = 'Y') AS active_promo_count,
    promo_total.total_store_sales_for_promo
FROM joined_data jd
CROSS JOIN LATERAL (
    SELECT SUM(ss2.ss_ext_sales_price) AS total_store_sales_for_promo
    FROM store_sales ss2
    WHERE ss2.ss_promo_sk = jd.store_promo_sk
) promo_total
WHERE jd.d_year = 2001
  AND jd.ca_state = 'TX'
  AND jd.cd_gender = 'M'
  AND jd.store_promo_discount = 'Y'
  AND jd.store_quantity > 5
  AND EXISTS (
      SELECT 1
      FROM web_returns wr2
      WHERE wr2.wr_order_number = jd.ws_order_number
        AND wr2.wr_net_loss > 0
  )
GROUP BY
    jd.d_year,
    jd.d_month_seq,
    jd.store_promo_name,
    jd.store_promo_discount,
    promo_total.total_store_sales_for_promo
ORDER BY total_net_profit DESC
LIMIT 100
