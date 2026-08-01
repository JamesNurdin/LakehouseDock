WITH
sales_sample AS (
    SELECT *
    FROM web_sales
    TABLESAMPLE BERNOULLI (10)
),
sales_agg AS (
    SELECT
        ws_order_number,
        ws_bill_hdemo_sk,
        ws_item_sk,
        SUM(ws_ext_sales_price) AS total_sales_price,
        SUM(ws_quantity) AS total_qty,
        AVG(ws_ext_tax) AS avg_ext_tax
    FROM sales_sample
    WHERE ws_ext_tax > 20
      AND ws_web_site_sk IN (14, 45)
    GROUP BY ws_order_number, ws_bill_hdemo_sk, ws_item_sk
),
returns_agg AS (
    SELECT
        wr_order_number,
        wr_refunded_hdemo_sk,
        wr_item_sk,
        SUM(wr_return_amt_inc_tax) AS total_return_amt,
        COUNT(*) AS cnt_return
    FROM web_returns
    WHERE wr_return_amt_inc_tax > 500
      AND wr_reason_sk IS NOT NULL
    GROUP BY wr_order_number, wr_refunded_hdemo_sk, wr_item_sk
),
intersect_demo AS (
    SELECT hd_demo_sk
    FROM household_demographics
    WHERE hd_buy_potential = '>10000'
    INTERSECT
    SELECT hd_demo_sk
    FROM household_demographics
    WHERE hd_dep_count > 2
),
except_demo AS (
    SELECT hd_demo_sk
    FROM household_demographics
    WHERE hd_buy_potential = '5001-10000'
    EXCEPT
    SELECT hd_demo_sk
    FROM household_demographics
    WHERE hd_dep_count = 0
),
joined AS (
    SELECT
        s.ws_order_number,
        s.ws_bill_hdemo_sk,
        s.ws_item_sk,
        s.total_sales_price,
        s.total_qty,
        s.avg_ext_tax,
        r.total_return_amt,
        r.cnt_return,
        hd_bill.hd_buy_potential,
        hd_bill.hd_dep_count
    FROM sales_agg s
    JOIN returns_agg r
        ON s.ws_order_number = r.wr_order_number
       AND s.ws_item_sk = r.wr_item_sk
    JOIN household_demographics hd_bill
        ON s.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN household_demographics hd_refund
        ON r.wr_refunded_hdemo_sk = hd_refund.hd_demo_sk
    WHERE hd_bill.hd_dep_count >= 1
      AND hd_bill.hd_demo_sk IN (SELECT hd_demo_sk FROM intersect_demo)
      AND hd_refund.hd_demo_sk NOT IN (SELECT hd_demo_sk FROM except_demo)
)
SELECT
    j.ws_order_number,
    j.ws_bill_hdemo_sk,
    j.ws_item_sk,
    j.total_sales_price,
    j.total_return_amt,
    j.hd_buy_potential,
    j.hd_dep_count,
    lateral_max.max_coupon_amt,
    ROW_NUMBER() OVER (ORDER BY j.total_sales_price DESC) AS rn
FROM joined j
CROSS JOIN LATERAL (
    SELECT MAX(ws_coupon_amt) AS max_coupon_amt
    FROM web_sales ws2
    WHERE ws2.ws_item_sk = j.ws_item_sk
) AS lateral_max
ORDER BY j.total_sales_price DESC
LIMIT 100
