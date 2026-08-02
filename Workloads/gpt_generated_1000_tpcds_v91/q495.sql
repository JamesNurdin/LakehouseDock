WITH inventory_summary AS (
    SELECT
        inv_date_sk,
        inv_warehouse_sk,
        SUM(inv_quantity_on_hand) AS total_qty_on_hand
    FROM inventory
    WHERE inv_quantity_on_hand > 500
    GROUP BY inv_date_sk, inv_warehouse_sk
)
SELECT
    d_year,
    p_promo_name,
    w_warehouse_name,
    total_sales,
    total_profit,
    distinct_customers,
    avg_store_quantity,
    total_inventory_on_hand,
    lateral_total_qty,
    total_promo_count,
    SUM(total_sales) OVER (PARTITION BY d_year ORDER BY total_sales ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_sales_year
FROM (
    SELECT
        d.d_year AS d_year,
        p.p_promo_name AS p_promo_name,
        w.w_warehouse_name AS w_warehouse_name,
        SUM(ss.ss_ext_sales_price + ws.ws_ext_sales_price) AS total_sales,
        SUM(ss.ss_net_profit + ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT c.c_customer_id) AS distinct_customers,
        AVG(ss.ss_quantity) AS avg_store_quantity,
        SUM(inv_sum.total_qty_on_hand) AS total_inventory_on_hand,
        MAX(inv_lateral.lateral_total_qty) AS lateral_total_qty,
        (SELECT COUNT(DISTINCT p2.p_promo_name) FROM promotion p2) AS total_promo_count
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
        AND ws.ws_bill_customer_sk = c.c_customer_sk
        AND ws.ws_bill_addr_sk = ca.ca_address_sk
        AND ws.ws_promo_sk = p.p_promo_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN inventory_summary inv_sum ON inv_sum.inv_date_sk = d.d_date_sk
        AND inv_sum.inv_warehouse_sk = w.w_warehouse_sk
    JOIN call_center cc ON cc.cc_open_date_sk = d.d_date_sk
    CROSS JOIN LATERAL (
        SELECT SUM(i.inv_quantity_on_hand) AS lateral_total_qty
        FROM inventory i
        WHERE i.inv_date_sk = d.d_date_sk
          AND i.inv_warehouse_sk = w.w_warehouse_sk
    ) AS inv_lateral
    WHERE d.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
      AND p.p_promo_name = 'pri'
      AND c.c_birth_month = 6
      AND NOT EXISTS (
          SELECT 1
          FROM web_returns wr
          WHERE wr.wr_order_number = ws.ws_order_number
      )
    GROUP BY ROLLUP(d.d_year, p.p_promo_name, w.w_warehouse_name)
) t
ORDER BY d_year, p_promo_name, w_warehouse_name
LIMIT 100
