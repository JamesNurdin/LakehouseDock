WITH
orders_all AS (
    SELECT cs.cs_order_number AS order_number
    FROM catalog_sales cs
    WHERE cs.cs_quantity > 0
),
orders_with_return AS (
    SELECT cr.cr_order_number AS order_number
    FROM catalog_returns cr
),
orders_without_return AS (
    SELECT order_number
    FROM orders_all
    EXCEPT
    SELECT order_number
    FROM orders_with_return
),
base_sales AS (
    SELECT
        s.s_store_name AS s_store_name,
        s.s_state AS s_state,
        p.p_promo_id AS p_promo_id,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        ss.ss_sales_price,
        ss.ss_quantity,
        ss.ss_net_profit AS store_net_profit,
        cs.cs_net_paid_inc_ship_tax,
        cs.cs_ext_discount_amt,
        cs.cs_ext_ship_cost,
        cs.cs_net_profit AS catalog_net_profit,
        cr.cr_net_loss AS catalog_return_loss,
        ws.ws_net_paid_inc_ship_tax,
        ws.ws_ext_discount_amt,
        ws.ws_ext_ship_cost,
        ws.ws_net_profit AS web_net_profit,
        hd.hd_vehicle_count,
        hd.hd_income_band_sk,
        ca.ca_city,
        ca.ca_zip,
        wp.wp_type,
        (ss.ss_net_profit + cs.cs_net_profit - cr.cr_net_loss + ws.ws_net_profit) AS total_profit
    FROM store_sales ss
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN catalog_sales cs
        ON cs.cs_bill_addr_sk = ca.ca_address_sk
           AND cs.cs_bill_hdemo_sk = hd.hd_demo_sk
           AND cs.cs_promo_sk = p.p_promo_sk
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
           AND cr.cr_refunded_addr_sk = ca.ca_address_sk
           AND cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
           AND cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN web_sales ws
        ON ws.ws_bill_addr_sk = ca.ca_address_sk
           AND ws.ws_bill_hdemo_sk = hd.hd_demo_sk
           AND ws.ws_promo_sk = p.p_promo_sk
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN orders_without_return owr
        ON cs.cs_order_number = owr.order_number
    WHERE s.s_state = 'CA'
      AND ca.ca_state = 'CA'
      AND p.p_discount_active = 'Y'
      AND hd.hd_vehicle_count >= 2
      AND ib.ib_lower_bound >= 50000
      AND ss.ss_sales_price > 20
      AND cs.cs_net_paid_inc_ship_tax > 1000
      AND EXISTS (
          SELECT 1
          FROM web_returns wr
          WHERE wr.wr_order_number = ws.ws_order_number
            AND wr.wr_return_quantity > 0
      )
),
agg_sales AS (
    SELECT
        s_state,
        s_store_name,
        p_promo_id,
        ib_lower_bound,
        ib_upper_bound,
        CASE
            WHEN total_profit > 20000 THEN 'High'
            WHEN total_profit > 10000 THEN 'Medium'
            ELSE 'Low'
        END AS profit_category,
        SUM(total_profit) AS sum_total_profit,
        COUNT(*) AS order_count
    FROM base_sales
    GROUP BY
        s_state,
        s_store_name,
        p_promo_id,
        ib_lower_bound,
        ib_upper_bound,
        CASE
            WHEN total_profit > 20000 THEN 'High'
            WHEN total_profit > 10000 THEN 'Medium'
            ELSE 'Low'
        END
    HAVING SUM(total_profit) > 5000
)
SELECT
    s_state,
    s_store_name,
    p_promo_id,
    profit_category,
    sum_total_profit,
    order_count,
    AVG(sum_total_profit) OVER (PARTITION BY s_state) AS avg_state_profit
FROM agg_sales
ORDER BY sum_total_profit DESC
LIMIT 100
