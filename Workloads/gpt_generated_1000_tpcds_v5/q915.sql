WITH filtered_sales AS (
    SELECT
        cs_sold_date_sk,
        cs_sold_time_sk,
        cs_ship_date_sk,
        cs_bill_customer_sk,
        cs_bill_hdemo_sk,
        cs_bill_addr_sk,
        cs_ship_customer_sk,
        cs_ship_addr_sk,
        cs_call_center_sk,
        cs_catalog_page_sk,
        cs_ship_mode_sk,
        cs_warehouse_sk,
        cs_item_sk,
        cs_promo_sk,
        cs_order_number,
        cs_quantity,
        cs_net_paid_inc_tax,
        cs_net_paid_inc_ship_tax,
        cs_net_profit
    FROM tpcds.catalog_sales
    WHERE cs_bill_hdemo_sk IN (6547, 6833)
      AND cs_net_paid_inc_tax > 1000
      AND cs_quantity > 1
)
SELECT
    sm.sm_ship_mode_id,
    p.p_promo_id,
    SUM(fs.cs_net_paid_inc_tax) AS total_net_paid_inc_tax,
    AVG(fs.cs_quantity) AS avg_quantity,
    COUNT(DISTINCT fs.cs_order_number) AS distinct_orders,
    CASE
        WHEN SUM(fs.cs_net_paid_inc_tax) > 50000 THEN 'HIGH'
        WHEN SUM(fs.cs_net_paid_inc_tax) > 20000 THEN 'MEDIUM'
        ELSE 'LOW'
    END AS revenue_category
FROM filtered_sales fs
JOIN tpcds.promotion p
    ON fs.cs_promo_sk = p.p_promo_sk
JOIN tpcds.ship_mode sm
    ON fs.cs_ship_mode_sk = sm.sm_ship_mode_sk
WHERE p.p_response_target = 1
  AND p.p_channel_demo = 'N'
  AND sm.sm_contract = 'I3uCelXtjP'
GROUP BY sm.sm_ship_mode_id, p.p_promo_id
HAVING SUM(fs.cs_net_paid_inc_tax) > 10000
ORDER BY total_net_paid_inc_tax DESC
LIMIT 100
