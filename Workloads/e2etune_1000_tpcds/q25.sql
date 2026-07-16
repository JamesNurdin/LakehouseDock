WITH sales AS (
    SELECT
        cs.cs_order_number,
        cs.cs_item_sk,
        cs.cs_sold_date_sk,
        cs.cs_net_paid_inc_tax,
        cs.cs_net_profit,
        cs.cs_quantity,
        cs.cs_ship_mode_sk,
        cs.cs_bill_hdemo_sk,
        cs.cs_ship_hdemo_sk,
        cs.cs_promo_sk
    FROM catalog_sales cs
    WHERE cs.cs_net_paid_inc_tax > 0
),
returns AS (
    SELECT
        cr.cr_order_number,
        cr.cr_item_sk,
        cr.cr_returned_date_sk,
        cr.cr_return_amount,
        cr.cr_net_loss,
        cr.cr_ship_mode_sk,
        cr.cr_refunded_hdemo_sk,
        cr.cr_returning_hdemo_sk
    FROM catalog_returns cr
    WHERE cr.cr_return_amount > 0
),
base AS (
    SELECT
        d.d_year AS sales_year,
        i.i_category AS item_category,
        ib.ib_income_band_sk AS income_band_id,
        sm.sm_type AS ship_mode_type,
        SUM(s.cs_net_paid_inc_tax) AS total_sales_amount,
        SUM(r.cr_return_amount) AS total_return_amount,
        SUM(r.cr_net_loss) AS total_net_loss,
        SUM(s.cs_net_profit) AS total_net_profit,
        COUNT(DISTINCT s.cs_order_number) AS distinct_orders
    FROM sales s
    JOIN returns r
        ON s.cs_order_number = r.cr_order_number
        AND s.cs_item_sk = r.cr_item_sk
    JOIN date_dim d
        ON s.cs_sold_date_sk = d.d_date_sk
    JOIN item i
        ON s.cs_item_sk = i.i_item_sk
    JOIN household_demographics hd_sales
        ON s.cs_bill_hdemo_sk = hd_sales.hd_demo_sk
    JOIN income_band ib
        ON hd_sales.hd_income_band_sk = ib.ib_income_band_sk
    JOIN ship_mode sm
        ON s.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN promotion p
        ON s.cs_promo_sk = p.p_promo_sk
    JOIN date_dim d_start
        ON p.p_start_date_sk = d_start.d_date_sk
    JOIN date_dim d_end
        ON p.p_end_date_sk = d_end.d_date_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
      AND p.p_channel_email = 'Y'
      AND ib.ib_lower_bound >= 50000
      AND d_start.d_date <= d.d_date
      AND d_end.d_date >= d.d_date
    GROUP BY d.d_year, i.i_category, ib.ib_income_band_sk, sm.sm_type
)
SELECT
    sales_year,
    item_category,
    income_band_id,
    ship_mode_type,
    total_sales_amount,
    total_return_amount,
    total_net_loss,
    total_net_profit - total_net_loss AS net_profit_after_returns,
    distinct_orders,
    RANK() OVER (PARTITION BY sales_year ORDER BY total_net_loss DESC) AS loss_rank
FROM base
ORDER BY total_net_loss DESC
LIMIT 100
