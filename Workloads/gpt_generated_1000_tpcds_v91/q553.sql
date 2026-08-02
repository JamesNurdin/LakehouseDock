WITH base AS (
    SELECT
        s.s_store_name AS store_name,
        d.d_year AS year,
        d.d_month_seq AS month_seq,
        i.i_item_sk AS item_sk,
        i.i_category AS category,
        p.p_promo_name AS promo_name,
        SUM(ss.ss_net_profit) AS store_net_profit,
        SUM(ss.ss_quantity) AS total_quantity,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(sr.sr_net_loss) AS total_store_return_loss,
        SUM(ws.ws_net_profit) AS web_net_profit,
        SUM(ws.ws_quantity) AS total_web_quantity,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        ARRAY[CAST(ss.ss_quantity AS double), CAST(ss.ss_sales_price AS double)] AS sale_metrics
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN inventory inv ON inv.inv_date_sk = d.d_date_sk AND inv.inv_item_sk = i.i_item_sk
    LEFT JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
    JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk AND ws.ws_sold_date_sk = d.d_date_sk
    JOIN catalog_returns cr ON cr.cr_item_sk = i.i_item_sk AND cr.cr_returned_date_sk = d.d_date_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
    JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    WHERE d.d_year = 1999
      AND s.s_state = 'CA'
      AND i.i_brand = 'Brand#12'
      AND p.p_discount_active = 'Y'
      AND sm.sm_type = 'EXPRESS'
      AND cc.cc_country = 'United States'
    GROUP BY s.s_store_name, d.d_year, d.d_month_seq, i.i_item_sk, i.i_category, p.p_promo_name,
             ARRAY[CAST(ss.ss_quantity AS double), CAST(ss.ss_sales_price AS double)]
)
SELECT
    store_name,
    year,
    month_seq,
    category,
    promo_name,
    store_net_profit,
    total_quantity,
    total_sales,
    total_store_return_loss,
    web_net_profit,
    total_web_quantity,
    total_web_sales,
    metric_element,
    avg_metric
FROM (
    SELECT
        b.*, 
        metric_element,
        AVG(metric_element) OVER (PARTITION BY store_name) AS avg_metric
    FROM base b
    CROSS JOIN UNNEST(b.sale_metrics) AS t(metric_element)
) x
WHERE EXISTS (
    SELECT 1
    FROM catalog_returns cr2
    JOIN call_center cc2 ON cr2.cr_call_center_sk = cc2.cc_call_center_sk
    WHERE cr2.cr_item_sk = x.item_sk
      AND cc2.cc_city = 'New York'
)
GROUP BY
    store_name,
    year,
    month_seq,
    category,
    promo_name,
    store_net_profit,
    total_quantity,
    total_sales,
    total_store_return_loss,
    web_net_profit,
    total_web_quantity,
    total_web_sales,
    metric_element,
    avg_metric
HAVING store_net_profit > 10000
   AND total_sales > 50000
   AND total_store_return_loss < 5000
ORDER BY store_net_profit DESC, year, month_seq
LIMIT 100
