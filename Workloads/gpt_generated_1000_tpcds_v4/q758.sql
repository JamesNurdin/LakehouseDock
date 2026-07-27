WITH filtered_sales AS (
    SELECT
        ss_sold_date_sk,
        ss_sold_time_sk,
        ss_item_sk,
        ss_customer_sk,
        ss_cdemo_sk,
        ss_hdemo_sk,
        ss_addr_sk,
        ss_store_sk,
        ss_promo_sk,
        ss_ticket_number,
        ss_quantity,
        ss_wholesale_cost,
        ss_list_price,
        ss_sales_price,
        ss_ext_discount_amt,
        ss_ext_sales_price,
        ss_ext_wholesale_cost,
        ss_ext_list_price,
        ss_ext_tax,
        ss_coupon_amt,
        ss_net_paid,
        ss_net_paid_inc_tax,
        ss_net_profit
    FROM store_sales
    WHERE ss_list_price > 20
      AND ss_coupon_amt < 500
      AND ss_quantity > 0
)
SELECT
    p.p_promo_id,
    t.t_hour,
    COUNT(*) AS sales_cnt,
    SUM(ss.ss_net_paid) AS total_net_paid,
    AVG(ss.ss_ext_discount_amt) AS avg_discount,
    MIN(ss.ss_list_price) AS min_list_price,
    MAX(ss.ss_coupon_amt) AS max_coupon_amt,
    SUM(CASE WHEN p.p_discount_active = 'Y' THEN ss.ss_net_paid ELSE ss.ss_net_paid * 0.9 END) AS adjusted_net_paid
FROM filtered_sales ss
INNER JOIN promotion p
    ON ss.ss_promo_sk = p.p_promo_sk
INNER JOIN time_dim t
    ON ss.ss_sold_time_sk = t.t_time_sk
WHERE p.p_channel_tv = 'N'
  AND p.p_channel_catalog = 'N'
  AND p.p_channel_event = 'N'
  AND t.t_hour BETWEEN 9 AND 17
  AND t.t_minute IN (9, 14, 15)
GROUP BY p.p_promo_id, t.t_hour
HAVING SUM(ss.ss_net_paid) > 5000
ORDER BY total_net_paid DESC
LIMIT 100
