/* Goal: Identify high‑profit web sales orders for customers born in July, after removing orders that meet an alternative low‑profit profile. */
WITH returns_agg AS (
    SELECT
        wr_order_number,
        SUM(wr_return_amt) AS total_return_amt,
        SUM(wr_net_loss) AS total_net_loss,
        COUNT(*) AS return_cnt
    FROM web_returns
    WHERE wr_return_quantity > 1
      AND wr_return_amt > 50
      AND wr_returned_date_sk BETWEEN 2450000 AND 2459999
      AND wr_fee < 20
      AND wr_account_credit >= 0
    GROUP BY wr_order_number
),

sales_agg AS (
    SELECT
        ws_order_number,
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(ws_net_profit) AS total_profit,
        COUNT(*) AS line_cnt
    FROM web_sales
    WHERE ws_ext_sales_price > 1000
      AND ws_coupon_amt < 200
      AND ws_ship_mode_sk IN (7, 8, 9, 12, 20)
      AND ws_wholesale_cost > 0
      AND ws_ext_discount_amt < 500
    GROUP BY ws_order_number
),

set_a AS (
    SELECT
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        hd.hd_demo_sk,
        p.p_promo_id,
        s.total_sales,
        s.total_profit,
        r.total_return_amt,
        r.total_net_loss
    FROM sales_agg s
    JOIN web_sales ws ON s.ws_order_number = ws.ws_order_number
    JOIN returns_agg r ON s.ws_order_number = r.wr_order_number
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE c.c_birth_month = 7
      AND c.c_birth_day BETWEEN 5 AND 25
      AND hd.hd_dep_count >= 3
      AND hd.hd_buy_potential = 'HIGH'
      AND p.p_discount_active = 'Y'
),

set_b AS (
    SELECT
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        hd.hd_demo_sk,
        p.p_promo_id,
        s.total_sales,
        s.total_profit,
        r.total_return_amt,
        r.total_net_loss
    FROM sales_agg s
    JOIN web_sales ws ON s.ws_order_number = ws.ws_order_number
    JOIN returns_agg r ON s.ws_order_number = r.wr_order_number
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE c.c_birth_month = 8
      AND c.c_birth_day BETWEEN 10 AND 30
      AND hd.hd_dep_count < 3
      AND hd.hd_buy_potential = 'LOW'
      AND p.p_discount_active = 'N'
)
SELECT *
FROM set_a
EXCEPT
SELECT *
FROM set_b
ORDER BY total_profit DESC
OFFSET 0 LIMIT 100
