WITH base AS (
    SELECT
        d.d_year AS d_year,
        d.d_quarter_name AS d_quarter_name,
        p.p_promo_name AS p_promo_name,
        hd.hd_buy_potential AS hd_buy_potential,
        ss.ss_ext_sales_price,
        ss.ss_net_paid_inc_tax,
        ss.ss_ext_discount_amt,
        ss.ss_net_profit,
        cr.cr_return_amount,
        cr.cr_net_loss,
        ss.ss_ticket_number
    FROM
        store_sales ss
        JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
        JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
        JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
        JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
        JOIN catalog_sales cs ON cs.cs_sold_date_sk = d.d_date_sk
            AND cs.cs_sold_time_sk = t.t_time_sk
            AND cs.cs_promo_sk = p.p_promo_sk
            AND cs.cs_bill_hdemo_sk = hd.hd_demo_sk
        JOIN catalog_returns cr ON cr.cr_returned_date_sk = d.d_date_sk
            AND cr.cr_returned_time_sk = t.t_time_sk
            AND cr.cr_item_sk = cs.cs_item_sk
            AND cr.cr_order_number = cs.cs_order_number
            AND cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    WHERE
        d.d_year = 2001
        AND d.d_quarter_name = '2001Q1'
        AND d.d_date >= DATE '2001-01-01'
        AND d.d_date < DATE '2002-01-01'
        AND t.t_hour BETWEEN 9 AND 17
        AND p.p_discount_active = 'Y'
        AND ss.ss_net_paid_inc_tax > 5000
),
agg AS (
    SELECT
        d_year,
        d_quarter_name,
        p_promo_name,
        hd_buy_potential,
        SUM(ss_ext_sales_price) AS total_sales,
        SUM(ss_net_paid_inc_tax) AS total_net_paid,
        SUM(ss_ext_discount_amt) AS total_discount,
        SUM(ss_net_profit) AS total_profit,
        SUM(cr_return_amount) AS total_return_amount,
        SUM(cr_net_loss) AS total_return_loss,
        COUNT(ss_ticket_number) AS sales_transactions,
        AVG(ss_ext_discount_amt) AS avg_discount,
        MIN(ss_ext_sales_price) AS min_sales,
        MAX(ss_ext_sales_price) AS max_sales
    FROM base
    GROUP BY d_year, d_quarter_name, p_promo_name, hd_buy_potential
)
SELECT
    d_year,
    d_quarter_name,
    p_promo_name,
    hd_buy_potential,
    total_sales,
    total_net_paid,
    total_discount,
    total_profit,
    total_return_amount,
    total_return_loss,
    sales_transactions,
    avg_discount,
    min_sales,
    max_sales,
    SUM(total_sales) OVER (
        PARTITION BY d_year
        ORDER BY d_quarter_name
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_sales_by_year
FROM agg
ORDER BY d_year, d_quarter_name, total_sales DESC
LIMIT 100
