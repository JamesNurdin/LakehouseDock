WITH base AS (
   SELECT
       ss.ss_sold_date_sk,
       ss.ss_ticket_number,
       ss.ss_quantity,
       ss.ss_net_profit,
       ss.ss_net_paid,
       ss.ss_store_sk,
       ss.ss_item_sk,
       ss.ss_promo_sk,
       i.i_brand,
       i.i_category,
       i.i_current_price,
       p.p_promo_name,
       p.p_discount_active,
       store.s_store_id,
       store.s_store_name,
       store.s_state,
       cd.cd_education_status,
       ca.ca_city
   FROM store_sales ss
   JOIN item i ON ss.ss_item_sk = i.i_item_sk
   JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
   JOIN store ON ss.ss_store_sk = store.s_store_sk
   JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
   JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
   WHERE store.s_state = 'CA'
     AND i.i_brand = 'Brand#10'
     AND cd.cd_education_status = 'Advanced Degree'
     AND p.p_discount_active = 'Y'
     AND i.i_current_price > 20
)
SELECT
    b.s_store_id,
    b.s_store_name,
    b.s_state,
    b.i_brand,
    b.i_category,
    COUNT(*) AS sales_cnt,
    SUM(b.ss_quantity) AS total_qty,
    SUM(b.ss_net_profit) AS total_net_profit,
    AVG(b.ss_net_paid) AS avg_net_paid,
    CASE
        WHEN SUM(b.ss_net_profit) > 5000 THEN 'High'
        WHEN SUM(b.ss_net_profit) > 0    THEN 'Medium'
        ELSE 'Low'
    END AS profit_level,
    b.running_net_paid,
    b.latest_promo_start
FROM (
   SELECT
       b.*,
       SUM(b.ss_net_paid) OVER (
           PARTITION BY b.s_store_id
           ORDER BY b.ss_sold_date_sk
           ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
       ) AS running_net_paid,
       lp.latest_promo_start
   FROM base b
   CROSS JOIN LATERAL (
       SELECT MAX(p2.p_start_date_sk) AS latest_promo_start
       FROM promotion p2
       WHERE p2.p_promo_sk = b.ss_promo_sk
   ) lp
   WHERE NOT EXISTS (
       SELECT 1
       FROM catalog_returns cr
       WHERE cr.cr_order_number = b.ss_ticket_number
   )
) b
JOIN catalog_returns cr ON cr.cr_item_sk = b.ss_item_sk
JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
WHERE w.w_gmt_offset = -6.00
  AND cp.cp_department = 'Electronics'
GROUP BY
    b.s_store_id,
    b.s_store_name,
    b.s_state,
    b.i_brand,
    b.i_category,
    b.running_net_paid,
    b.latest_promo_start
ORDER BY total_net_profit DESC
LIMIT 100
