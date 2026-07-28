WITH sales_agg AS (
    SELECT
        sm.sm_type,
        d.d_year,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS order_cnt,
        SUM(ws.ws_ext_sales_price) AS total_sales
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN web_site we ON ws.ws_web_site_sk = we.web_site_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    WHERE d.d_year = 2020
      AND sm.sm_type = 'OVERNIGHT'
      AND p.p_discount_active = 'Y'
      AND cd.cd_dep_employed_count >= 3
      AND NOT EXISTS (
          SELECT 1
          FROM web_returns wr
          WHERE wr.wr_order_number = ws.ws_order_number
            AND wr.wr_reversed_charge > 100
      )
    GROUP BY sm.sm_type, d.d_year
)
SELECT
    sa.sm_type,
    sa.d_year,
    sa.total_profit,
    sa.order_cnt,
    sa.total_sales,
    RANK() OVER (ORDER BY sa.total_profit DESC) AS profit_rank,
    (SELECT AVG(p2.p_cost) FROM promotion p2 WHERE p2.p_discount_active = 'Y') AS avg_active_promo_cost
FROM sales_agg sa
ORDER BY sa.total_profit DESC
LIMIT 100
