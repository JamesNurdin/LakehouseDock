WITH base_agg AS (
    SELECT
        p.p_promo_id,
        sm.sm_type,
        SUM(cs.cs_net_paid_inc_ship) AS sum_catalog_net,
        SUM(ss.ss_sales_price) AS sum_store_sales,
        SUM(wr.wr_return_amt) AS sum_web_return_amt,
        COUNT(DISTINCT cs.cs_order_number) AS cnt_orders
    FROM catalog_sales cs
    JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN store_sales ss ON td.t_time_sk = ss.ss_sold_time_sk
    JOIN store_returns sr ON ss.ss_item_sk = sr.sr_item_sk
        AND ss.ss_ticket_number = sr.sr_ticket_number
    JOIN web_sales ws ON td.t_time_sk = ws.ws_sold_time_sk
    JOIN web_returns wr ON ws.ws_order_number = wr.wr_order_number
    WHERE cs.cs_net_paid_inc_ship > 3000
      AND cs.cs_wholesale_cost < 50
      AND p.p_cost BETWEEN 500 AND 1500
      AND sm.sm_carrier = 'UPS'
      AND ss.ss_sales_price > 0
      AND td.t_hour BETWEEN 9 AND 17
      AND ws.ws_quantity >= 1
      AND wr.wr_return_quantity > 0
    GROUP BY p.p_promo_id, sm.sm_type
),
overall_totals AS (
    SELECT
        SUM(cs.cs_net_paid_inc_ship) AS total_catalog_net,
        (SELECT COUNT(*) FROM catalog_sales) AS total_orders
    FROM catalog_sales cs
    WHERE cs.cs_net_paid_inc_ship > 2000
),
filtered_agg AS (
    SELECT
        ba.*, ot.total_catalog_net, ot.total_orders
    FROM base_agg ba
    CROSS JOIN overall_totals ot
    WHERE ba.sum_catalog_net > ot.total_catalog_net / 10
)
SELECT
    f.p_promo_id,
    f.sm_type,
    f.sum_catalog_net,
    f.sum_store_sales,
    f.cnt_orders,
    f.total_orders
FROM filtered_agg f
WHERE f.cnt_orders > 5
UNION ALL
SELECT
    f.p_promo_id,
    f.sm_type,
    f.sum_catalog_net,
    f.sum_store_sales,
    f.cnt_orders,
    f.total_orders
FROM filtered_agg f
WHERE f.sum_store_sales > 5000
ORDER BY sum_catalog_net DESC
LIMIT 100
