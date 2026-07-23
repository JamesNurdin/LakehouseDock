WITH ss_agg AS (
    SELECT
        ss_ticket_number,
        ss_store_sk,
        ss_customer_sk,
        ss_cdemo_sk,
        ss_hdemo_sk,
        ss_addr_sk,
        ss_item_sk,
        SUM(ss_net_paid) AS total_sales_amount,
        SUM(ss_quantity) AS total_quantity,
        SUM(ss_net_profit) AS total_profit
    FROM store_sales
    WHERE ss_net_paid > 0
      AND ss_quantity > 0
      AND ss_wholesale_cost > 0
      AND ss_list_price > ss_wholesale_cost
      AND ss_ext_discount_amt >= 0
      AND ss_ext_sales_price >= ss_wholesale_cost
    GROUP BY ss_ticket_number, ss_store_sk, ss_customer_sk, ss_cdemo_sk, ss_hdemo_sk, ss_addr_sk, ss_item_sk
),
sr_agg AS (
    SELECT
        sr_ticket_number,
        SUM(sr_return_amt) AS total_return_amount,
        COUNT(*) AS return_cnt
    FROM store_returns
    WHERE sr_return_quantity > 0
      AND sr_return_amt > 0
      AND sr_fee >= 0
      AND sr_refunded_cash >= 0
      AND sr_net_loss >= 0
      AND sr_store_credit >= 0
    GROUP BY sr_ticket_number
),
ws_agg AS (
    SELECT
        ws_bill_customer_sk,
        SUM(ws_net_paid) AS total_web_sales,
        COUNT(DISTINCT ws_order_number) AS distinct_orders
    FROM web_sales
    WHERE ws_net_paid > 0
      AND ws_quantity > 0
      AND ws_ext_discount_amt >= 0
      AND ws_ext_sales_price > 0
      AND ws_ext_tax >= 0
      AND ws_net_paid_inc_ship > 0
    GROUP BY ws_bill_customer_sk
)
SELECT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    s.s_store_name,
    s.s_city,
    s.s_state,
    ca.ca_city AS customer_city,
    ca.ca_state AS customer_state,
    cd.cd_gender,
    cd.cd_marital_status,
    hd.hd_buy_potential,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    SUM(ss_agg.total_sales_amount) AS net_sales_amount,
    SUM(ss_agg.total_quantity) AS total_quantity_sold,
    SUM(ss_agg.total_profit) AS total_profit,
    SUM(COALESCE(sr_agg.total_return_amount, 0)) AS total_return_amount,
    SUM(COALESCE(sr_agg.return_cnt, 0)) AS total_return_count,
    MAX(ws_agg.total_web_sales) AS total_web_sales,
    MAX(ws_agg.distinct_orders) AS distinct_web_orders,
    (SUM(ss_agg.total_sales_amount) - SUM(COALESCE(sr_agg.total_return_amount, 0))) AS net_sales_minus_returns,
    (SUM(ss_agg.total_profit) - SUM(COALESCE(sr_agg.total_return_amount, 0))) AS net_profit_after_returns,
    (SUM(ss_agg.total_sales_amount) / NULLIF(MAX(ws_agg.total_web_sales), 0)) AS sales_to_web_ratio,
    COUNT(DISTINCT ss_agg.ss_item_sk) AS distinct_items_sold
FROM ss_agg
JOIN store s ON ss_agg.ss_store_sk = s.s_store_sk
JOIN customer c ON ss_agg.ss_customer_sk = c.c_customer_sk
JOIN customer_address ca ON ss_agg.ss_addr_sk = ca.ca_address_sk
JOIN customer_demographics cd ON ss_agg.ss_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd ON ss_agg.ss_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
LEFT JOIN sr_agg ON sr_agg.sr_ticket_number = ss_agg.ss_ticket_number
LEFT JOIN ws_agg ON ws_agg.ws_bill_customer_sk = c.c_customer_sk
WHERE s.s_gmt_offset BETWEEN -5.00 AND 5.00
  AND s.s_tax_percentage < 0.10
  AND ca.ca_country = 'United States'
  AND cd.cd_credit_rating IN ('Excellent', 'Good')
  AND hd.hd_dep_count >= 1
  AND ib.ib_upper_bound > 50000
  AND c.c_preferred_cust_flag = 'Y'
  AND EXISTS (
      SELECT 1
      FROM web_sales ws
      WHERE ws.ws_bill_customer_sk = c.c_customer_sk
        AND ws.ws_net_paid > 2000
        AND ws.ws_ship_mode_sk = 1
  )
GROUP BY
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    s.s_store_name,
    s.s_city,
    s.s_state,
    ca.ca_city,
    ca.ca_state,
    cd.cd_gender,
    cd.cd_marital_status,
    hd.hd_buy_potential,
    ib.ib_lower_bound,
    ib.ib_upper_bound
HAVING COUNT(DISTINCT ss_agg.ss_item_sk) > 5
ORDER BY net_sales_minus_returns DESC
LIMIT 100
