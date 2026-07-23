WITH cs_base AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_ship_date_sk,
        cs.cs_bill_addr_sk,
        cs.cs_ship_addr_sk,
        cs.cs_ship_mode_sk,
        cs.cs_item_sk,
        cs.cs_promo_sk,
        cs.cs_order_number,
        cs.cs_quantity,
        cs.cs_ext_sales_price,
        cs.cs_net_paid,
        cs.cs_ext_discount_amt,
        cs.cs_net_profit
    FROM catalog_sales cs
    JOIN date_dim d_sold ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE d_sold.d_year = 2001
      AND sm.sm_type = 'OVERNIGHT'
)
SELECT
    i.i_category,
    i.i_brand,
    d_sold.d_year,
    sm.sm_type,
    ca.ca_state,
    ws.web_state,
    COUNT(DISTINCT cs_base.cs_order_number) AS distinct_orders,
    SUM(cs_base.cs_net_paid) AS total_net_paid,
    SUM(cs_base.cs_ext_discount_amt) AS total_discount,
    AVG(sr.sr_return_amt) AS avg_return_amount,
    SUM(CASE WHEN cs_base.cs_quantity > 5 THEN cs_base.cs_net_paid ELSE 0 END) AS high_qty_sales,
    SUM(CASE WHEN cs_base.cs_net_paid > (
        SELECT AVG(p2.p_cost) FROM promotion p2 WHERE p2.p_discount_active = 'Y'
    ) THEN cs_base.cs_net_paid ELSE 0 END) AS above_avg_promo_cost_sales,
    MIN(d_sold.d_date) AS first_sale_date,
    MAX(d_sold.d_date) AS last_sale_date
FROM cs_base
JOIN item i ON cs_base.cs_item_sk = i.i_item_sk
JOIN promotion p ON cs_base.cs_promo_sk = p.p_promo_sk
    AND p.p_item_sk = i.i_item_sk
JOIN customer_address ca ON cs_base.cs_bill_addr_sk = ca.ca_address_sk
JOIN ship_mode sm ON cs_base.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN date_dim d_sold ON cs_base.cs_sold_date_sk = d_sold.d_date_sk
JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk
JOIN date_dim d_sr ON sr.sr_returned_date_sk = d_sr.d_date_sk
JOIN customer_address ca_sr ON sr.sr_addr_sk = ca_sr.ca_address_sk
CROSS JOIN web_site ws
JOIN date_dim d_ws_open ON ws.web_open_date_sk = d_ws_open.d_date_sk
JOIN date_dim d_ws_close ON ws.web_close_date_sk = d_ws_close.d_date_sk
JOIN date_dim d_promo_start ON p.p_start_date_sk = d_promo_start.d_date_sk
JOIN date_dim d_promo_end ON p.p_end_date_sk = d_promo_end.d_date_sk
WHERE ca.ca_country = 'United States'
  AND p.p_discount_active = 'Y'
  AND ws.web_state = 'CA'
  AND sr.sr_return_quantity > 0
GROUP BY
    i.i_category,
    i.i_brand,
    d_sold.d_year,
    sm.sm_type,
    ca.ca_state,
    ws.web_state
LIMIT 100
