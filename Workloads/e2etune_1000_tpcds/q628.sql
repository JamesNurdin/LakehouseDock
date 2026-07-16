WITH sales AS (
    SELECT
        cs.cs_order_number,
        cs.cs_item_sk,
        cs.cs_warehouse_sk,
        cs.cs_bill_hdemo_sk AS hd_demo_sk,
        cs.cs_quantity AS sold_qty,
        cs.cs_net_profit AS net_profit,
        cs.cs_sold_date_sk
    FROM catalog_sales cs
    WHERE cs.cs_sold_date_sk BETWEEN 2451000 AND 2451100
),
returns AS (
    SELECT
        cr.cr_order_number,
        cr.cr_item_sk,
        cr.cr_return_quantity AS returned_qty,
        cr.cr_return_amount AS return_amount,
        cr.cr_returned_date_sk
    FROM catalog_returns cr
    WHERE cr.cr_returned_date_sk BETWEEN 2451000 AND 2451100
),
sales_with_returns AS (
    SELECT
        s.hd_demo_sk,
        s.sold_qty,
        COALESCE(r.returned_qty, 0) AS returned_qty,
        s.net_profit,
        COALESCE(r.return_amount, 0) AS return_amount
    FROM sales s
    LEFT JOIN returns r
        ON s.cs_order_number = r.cr_order_number
        AND s.cs_item_sk = r.cr_item_sk
),
agg AS (
    SELECT
        hd.hd_income_band_sk,
        hd.hd_buy_potential,
        COUNT(*) AS num_orders,
        SUM(swr.sold_qty) AS total_quantity_sold,
        SUM(swr.returned_qty) AS total_quantity_returned,
        SUM(swr.net_profit) - SUM(swr.return_amount) AS net_profit_after_returns,
        AVG((swr.net_profit - swr.return_amount) / NULLIF(swr.sold_qty, 0)) AS avg_profit_per_item,
        (SUM(swr.returned_qty) / NULLIF(SUM(swr.sold_qty), 0)) AS return_rate
    FROM sales_with_returns swr
    JOIN household_demographics hd
        ON swr.hd_demo_sk = hd.hd_demo_sk
    GROUP BY hd.hd_income_band_sk, hd.hd_buy_potential
)
SELECT
    hd_income_band_sk,
    hd_buy_potential,
    num_orders,
    total_quantity_sold,
    total_quantity_returned,
    net_profit_after_returns,
    avg_profit_per_item,
    return_rate,
    RANK() OVER (ORDER BY avg_profit_per_item DESC) AS profit_rank
FROM agg
ORDER BY avg_profit_per_item DESC
LIMIT 5
