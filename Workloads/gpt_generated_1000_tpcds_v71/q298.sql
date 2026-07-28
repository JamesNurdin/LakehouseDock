WITH sales_by_store_cc AS (
    SELECT
        s.s_store_id,
        cc.cc_call_center_id,
        d_sold.d_year,
        SUM(cs.cs_net_profit) AS total_profit,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        COUNT(*) AS order_cnt
    FROM catalog_sales cs
    JOIN date_dim d_sold
        ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN date_dim d_ship
        ON cs.cs_ship_date_sk = d_ship.d_date_sk
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    JOIN date_dim d_promo_start
        ON p.p_start_date_sk = d_promo_start.d_date_sk
    JOIN date_dim d_promo_end
        ON p.p_end_date_sk = d_promo_end.d_date_sk
    JOIN inventory inv
        ON inv.inv_date_sk = d_sold.d_date_sk
    JOIN store s
        ON s.s_closed_date_sk = d_sold.d_date_sk
    WHERE d_sold.d_year = 2021
      AND s.s_state = 'CA'
      AND s.s_city IN ('Los Angeles', 'San Francisco')
      AND cc.cc_state = 'CA'
      AND p.p_discount_active = 'Y'
      AND inv.inv_quantity_on_hand < 100
      AND cs.cs_quantity > 5
      AND cs.cs_net_profit > 0
      AND cs.cs_item_sk IN (
          SELECT inv2.inv_item_sk
          FROM inventory inv2
          WHERE inv2.inv_quantity_on_hand < 50
      )
    GROUP BY s.s_store_id, cc.cc_call_center_id, d_sold.d_year
)
SELECT
    s_store_id,
    cc_call_center_id,
    d_year,
    total_profit,
    total_sales,
    order_cnt,
    total_profit / NULLIF(total_sales, 0) AS profit_margin
FROM sales_by_store_cc
WHERE total_profit > (
    SELECT AVG(total_profit)
    FROM sales_by_store_cc
)
ORDER BY profit_margin DESC
LIMIT 100
