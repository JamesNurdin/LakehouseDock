WITH sales_agg AS (
    SELECT
        d_sold.d_current_month,
        d_sold.d_year,
        s.s_store_id,
        s.s_store_name,
        hd_bill.hd_buy_potential,
        hd_ship.hd_vehicle_count,
        p.p_promo_id,
        p.p_channel_email,
        d_promo_start.d_date AS promo_start_date,
        d_promo_end.d_date   AS promo_end_date,
        SUM(ws.ws_net_paid)          AS total_net_paid,
        SUM(ws.ws_ext_sales_price)   AS total_sales,
        AVG(p.p_cost)                AS avg_promo_cost,
        COUNT(*)                     AS txn_count
    FROM web_sales ws
    JOIN date_dim d_sold
        ON ws.ws_sold_date_sk = d_sold.d_date_sk
    JOIN date_dim d_ship
        ON ws.ws_ship_date_sk = d_ship.d_date_sk
    JOIN household_demographics hd_bill
        ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN household_demographics hd_ship
        ON ws.ws_ship_hdemo_sk = hd_ship.hd_demo_sk
    JOIN promotion p
        ON ws.ws_promo_sk = p.p_promo_sk
    JOIN store s
        ON s.s_closed_date_sk = d_sold.d_date_sk
    JOIN date_dim d_promo_start
        ON p.p_start_date_sk = d_promo_start.d_date_sk
    JOIN date_dim d_promo_end
        ON p.p_end_date_sk = d_promo_end.d_date_sk
    GROUP BY
        d_sold.d_current_month,
        d_sold.d_year,
        s.s_store_id,
        s.s_store_name,
        hd_bill.hd_buy_potential,
        hd_ship.hd_vehicle_count,
        p.p_promo_id,
        p.p_channel_email,
        d_promo_start.d_date,
        d_promo_end.d_date
)
SELECT
    d_current_month,
    d_year,
    s_store_id,
    s_store_name,
    hd_buy_potential,
    hd_vehicle_count,
    p_promo_id,
    p_channel_email,
    promo_start_date,
    promo_end_date,
    date_diff('day', promo_start_date, promo_end_date) AS promo_duration_days,
    total_net_paid,
    total_sales,
    avg_promo_cost,
    txn_count,
    RANK() OVER (PARTITION BY d_current_month ORDER BY total_net_paid DESC) AS month_store_net_paid_rank
FROM sales_agg
ORDER BY d_year DESC, d_current_month, month_store_net_paid_rank
LIMIT 100
