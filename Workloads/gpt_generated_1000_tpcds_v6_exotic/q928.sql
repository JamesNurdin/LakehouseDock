WITH sales_detail AS (
    SELECT
        ws_bill_customer_sk,
        ws_item_sk,
        MAX(ws_ship_mode_sk) AS ship_mode_sk,
        MAX(ws_warehouse_sk) AS warehouse_sk,
        MAX(ws_web_page_sk) AS web_page_sk,
        MAX(ws_web_site_sk) AS web_site_sk
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 2450000 AND 2451000
    GROUP BY ws_bill_customer_sk, ws_item_sk
),

sales_agg AS (
    SELECT
        ws_bill_customer_sk AS customer_sk,
        ws_item_sk AS item_sk,
        SUM(ws_net_profit) AS total_profit,
        SUM(ws_quantity) AS total_quantity,
        COUNT(*) AS sales_cnt
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 2450000 AND 2451000
    GROUP BY ws_bill_customer_sk, ws_item_sk
)
SELECT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    i.i_item_id,
    i.i_product_name,
    sa.total_profit,
    sa.total_quantity,
    sa.sales_cnt,
    CASE WHEN hd.hd_vehicle_count > 2 THEN 'High' ELSE 'Low' END AS vehicle_category,
    sm.sm_type,
    w.w_city,
    wp.wp_type,
    ws.web_name,
    (
        SELECT COUNT(*)
        FROM web_returns wr
        WHERE wr.wr_returning_customer_sk = c.c_customer_sk
          AND wr.wr_item_sk = i.i_item_sk
    ) AS return_cnt,
    RANK() OVER (PARTITION BY c.c_customer_id ORDER BY sa.total_profit DESC) AS profit_rank
FROM sales_agg sa
JOIN sales_detail sd
    ON sd.ws_bill_customer_sk = sa.customer_sk
   AND sd.ws_item_sk = sa.item_sk
JOIN customer c
    ON c.c_customer_sk = sa.customer_sk
JOIN household_demographics hd
    ON c.c_current_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN item i
    ON i.i_item_sk = sa.item_sk
JOIN inventory inv
    ON inv.inv_item_sk = i.i_item_sk
JOIN warehouse w
    ON w.w_warehouse_sk = sd.warehouse_sk
JOIN ship_mode sm
    ON sm.sm_ship_mode_sk = sd.ship_mode_sk
JOIN web_page wp
    ON wp.wp_web_page_sk = sd.web_page_sk
JOIN web_site ws
    ON ws.web_site_sk = sd.web_site_sk
WHERE i.i_current_price > 100
  AND w.w_state = 'CA'
  AND ib.ib_lower_bound >= 50000
  AND c.c_salutation = 'Dr.'
  AND hd.hd_vehicle_count >= 2
  AND inv.inv_quantity_on_hand > 0
ORDER BY profit_rank, sa.total_profit DESC
LIMIT 100
