WITH sales_base AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_item_sk,
        ss.ss_customer_sk,
        ss.ss_hdemo_sk,
        ss.ss_promo_sk,
        ss.ss_store_sk,
        ss.ss_ticket_number,
        ss.ss_quantity,
        ss.ss_ext_sales_price,
        ss.ss_coupon_amt,
        ss.ss_net_paid_inc_tax,
        ss.ss_net_profit
    FROM store_sales ss
)
SELECT
    d.d_year,
    d.d_month_seq,
    p.p_promo_name,
    w.w_state,
    SUM(s.ss_ext_sales_price) AS total_sales,
    SUM(wr.wr_return_amt) AS total_returns,
    SUM(inv.inv_quantity_on_hand) AS total_inventory,
    AVG(s.ss_coupon_amt) AS avg_coupon_amount,
    COUNT(DISTINCT s.ss_ticket_number) AS distinct_tickets,
    MIN(s.ss_net_profit) AS min_net_profit,
    MAX(s.ss_net_profit) AS max_net_profit
FROM sales_base s
JOIN date_dim d ON s.ss_sold_date_sk = d.d_date_sk
JOIN household_demographics hd ON s.ss_hdemo_sk = hd.hd_demo_sk
JOIN promotion p ON s.ss_promo_sk = p.p_promo_sk
JOIN inventory inv ON d.d_date_sk = inv.inv_date_sk
JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
JOIN web_returns wr ON d.d_date_sk = wr.wr_returned_date_sk
    AND hd.hd_demo_sk = wr.wr_refunded_hdemo_sk
JOIN web_site ws ON ws.web_open_date_sk = d.d_date_sk
WHERE
    d.d_year = 2001
    AND d.d_month_seq BETWEEN 1200 AND 1300
    AND p.p_discount_active = 'Y'
    AND w.w_state = 'CA'
    AND hd.hd_vehicle_count >= 2
    AND ws.web_country = 'United States'
    AND EXISTS (
        SELECT 1
        FROM call_center cc
        WHERE cc.cc_closed_date_sk = d.d_date_sk
          AND cc.cc_tax_percentage > 0.05
          AND cc.cc_state = 'CA'
    )
GROUP BY
    d.d_year,
    d.d_month_seq,
    p.p_promo_name,
    w.w_state
HAVING
    SUM(s.ss_ext_sales_price) > 100000
    AND SUM(wr.wr_return_amt) < 50000
ORDER BY total_sales DESC
LIMIT 100
