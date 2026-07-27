/*
Goal: Identify the most valuable warehouse‑promotion combinations for California customers, showing revenue, profit, order count and profitability flag, filtered by various warehouse, site, promotion and address attributes.
*/
WITH sales_agg AS (
    SELECT
        ws_warehouse_sk,
        ws_promo_sk,
        ws_bill_addr_sk,
        ws_web_site_sk,
        SUM(ws_ext_sales_price)      AS total_sales,
        SUM(ws_net_profit)           AS total_profit,
        COUNT(*)                     AS order_cnt,
        AVG(ws_quantity)             AS avg_qty
    FROM web_sales
    WHERE ws_quantity > 0
      AND ws_ext_sales_price > 0
      AND ws_net_profit IS NOT NULL
    GROUP BY ws_warehouse_sk, ws_promo_sk, ws_bill_addr_sk, ws_web_site_sk
)
SELECT
    w.w_warehouse_name,
    w.w_state,
    w.w_city,
    p.p_promo_name,
    ca.ca_city,
    site.web_name,
    sales_agg.total_sales,
    sales_agg.total_profit,
    sales_agg.order_cnt,
    CASE WHEN sales_agg.total_profit > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_flag,
    sales_agg.total_sales / NULLIF(sales_agg.order_cnt, 0) AS avg_sales_per_order,
    sales_agg.avg_qty
FROM sales_agg
JOIN warehouse w        ON sales_agg.ws_warehouse_sk = w.w_warehouse_sk
JOIN promotion p        ON sales_agg.ws_promo_sk    = p.p_promo_sk
JOIN customer_address ca ON sales_agg.ws_bill_addr_sk = ca.ca_address_sk
JOIN web_site site      ON sales_agg.ws_web_site_sk = site.web_site_sk
WHERE w.w_state = 'CA'                                 -- 1. warehouse state filter
  AND w.w_zip LIKE '9%'                                 -- 2. warehouse zip filter
  AND site.web_tax_percentage >= 0.08                 -- 3. site tax filter
  AND site.web_rec_start_date BETWEEN DATE '2002-01-01' AND DATE '2004-12-31'  -- 4. site rec start date filter
  AND p.p_channel_email = 'Y'                          -- 5. promotion channel filter
  AND ca.ca_state = 'CA'                               -- 6. customer address state filter
  AND sales_agg.total_sales > 10000                    -- 7. revenue threshold filter
  AND EXISTS (
        SELECT 1
        FROM promotion p2
        WHERE p2.p_promo_sk = p.p_promo_sk
          AND p2.p_cost > 5000
      )                                                -- subquery filter on promotion cost
ORDER BY sales_agg.total_sales DESC
LIMIT 100
