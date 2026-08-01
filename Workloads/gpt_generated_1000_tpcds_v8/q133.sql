WITH ws_agg AS (
    SELECT
        ws_item_sk,
        ws_sold_date_sk,
        ws_web_page_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales,
        AVG(ws_wholesale_cost) AS avg_wholesale_cost,
        COUNT(*) AS order_count
    FROM web_sales
    WHERE ws_wholesale_cost > 50.00
      AND ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2001)
    GROUP BY ws_item_sk, ws_sold_date_sk, ws_web_page_sk
)
SELECT
    i.i_category,
    d_sr.d_year,
    p.p_promo_name,
    CASE WHEN cr.cr_net_loss > 1000 THEN 'High' ELSE 'Low' END AS net_loss_category,
    SUM(ws_agg.total_quantity) AS sum_quantity,
    SUM(ws_agg.total_sales) AS sum_sales,
    AVG(ws_agg.avg_wholesale_cost) AS avg_wholesale_cost,
    SUM(cr.cr_return_amount) AS total_return_amount,
    COUNT(DISTINCT cr.cr_order_number) AS distinct_return_orders,
    COUNT(DISTINCT sr.sr_ticket_number) AS distinct_store_return_tickets
FROM ws_agg
JOIN item i ON ws_agg.ws_item_sk = i.i_item_sk
JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk
JOIN date_dim d_sr ON sr.sr_returned_date_sk = d_sr.d_date_sk
JOIN catalog_returns cr ON cr.cr_item_sk = i.i_item_sk
JOIN date_dim d_cr ON cr.cr_returned_date_sk = d_cr.d_date_sk
JOIN promotion p ON p.p_item_sk = i.i_item_sk
JOIN web_page wp ON wp.wp_web_page_sk = ws_agg.ws_web_page_sk
JOIN date_dim d_wp_creation ON wp.wp_creation_date_sk = d_wp_creation.d_date_sk
JOIN customer c_refunded ON cr.cr_refunded_customer_sk = c_refunded.c_customer_sk
JOIN customer_demographics cd_refunded ON cr.cr_refunded_cdemo_sk = cd_refunded.cd_demo_sk
JOIN household_demographics hd_sr ON sr.sr_hdemo_sk = hd_sr.hd_demo_sk
JOIN customer_address ca_refunded ON cr.cr_refunded_addr_sk = ca_refunded.ca_address_sk
WHERE d_sr.d_year = 2001
  AND i.i_current_price > 100.00
  AND c_refunded.c_birth_country = 'United States'
  AND cd_refunded.cd_credit_rating = 'Good'
  AND p.p_discount_active = 'Y'
GROUP BY
    i.i_category,
    d_sr.d_year,
    p.p_promo_name,
    CASE WHEN cr.cr_net_loss > 1000 THEN 'High' ELSE 'Low' END
ORDER BY sum_sales DESC
LIMIT 100
