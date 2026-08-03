WITH filtered_sales AS (
    SELECT ws_sold_date_sk,
           ws_sold_time_sk,
           ws_ship_date_sk,
           ws_item_sk,
           ws_bill_customer_sk,
           ws_bill_cdemo_sk,
           ws_bill_hdemo_sk,
           ws_bill_addr_sk,
           ws_ship_customer_sk,
           ws_ship_cdemo_sk,
           ws_ship_hdemo_sk,
           ws_ship_addr_sk,
           ws_web_page_sk,
           ws_web_site_sk,
           ws_ship_mode_sk,
           ws_warehouse_sk,
           ws_promo_sk,
           ws_order_number,
           ws_quantity,
           ws_wholesale_cost,
           ws_list_price,
           ws_sales_price,
           ws_ext_discount_amt,
           ws_ext_sales_price,
           ws_ext_wholesale_cost,
           ws_ext_list_price,
           ws_ext_tax,
           ws_coupon_amt,
           ws_ext_ship_cost,
           ws_net_paid,
           ws_net_paid_inc_tax,
           ws_net_paid_inc_ship,
           ws_net_paid_inc_ship_tax,
           ws_net_profit
    FROM web_sales
    WHERE ws_quantity > 1
      AND ws_net_paid_inc_ship > 1000
      AND ws_ship_mode_sk IN (1, 2, 3)
      AND ws_warehouse_sk BETWEEN 4 AND 13
      AND ws_ship_customer_sk NOT IN (0)
      AND ws_web_site_sk IN (
          SELECT web_site_sk
          FROM web_site
          WHERE web_tax_percentage >= 0.05
      )
)
SELECT
    ws.ws_order_number,
    ws.ws_sold_date_sk,
    ws.ws_quantity,
    ws.ws_net_paid_inc_ship,
    ws.ws_net_profit,
    ws.ws_web_site_sk,
    s.web_name,
    CASE
        WHEN ws.ws_net_profit > 1000 THEN 'HIGH'
        WHEN ws.ws_net_profit BETWEEN 0 AND 1000 THEN 'MEDIUM'
        ELSE 'LOW'
    END AS profit_category,
    SUM(ws.ws_ext_sales_price) OVER (
        PARTITION BY ws.ws_web_site_sk
        ORDER BY ws.ws_sold_date_sk
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_sales,
    ROW_NUMBER() OVER (ORDER BY ws.ws_net_paid_inc_ship DESC) AS global_rank
FROM filtered_sales ws
JOIN web_site s
    ON ws.ws_web_site_sk = s.web_site_sk
WHERE s.web_state = 'CA'
  AND s.web_city LIKE 'C%'
ORDER BY global_rank
LIMIT 100
