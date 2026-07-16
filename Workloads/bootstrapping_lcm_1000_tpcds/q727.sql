WITH agg AS (
    SELECT
        s.s_store_sk,
        s.s_store_name,
        s.s_city,
        s.s_state,
        p.p_promo_name,
        p.p_channel_email,
        d_sold.d_year AS sold_year,
        d_ship.d_year AS ship_year,
        cd_bill.cd_gender AS bill_gender,
        cd_ship.cd_gender AS ship_gender,
        d_promo_start.d_date AS promo_start_date,
        d_promo_end.d_date AS promo_end_date,
        SUM(cs.cs_net_paid) AS total_net_paid,
        SUM(cs.cs_net_profit) AS total_net_profit,
        COUNT(DISTINCT cs.cs_order_number) AS distinct_orders
    FROM catalog_sales cs
    JOIN date_dim d_sold
        ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN date_dim d_ship
        ON cs.cs_ship_date_sk = d_ship.d_date_sk
    JOIN customer_demographics cd_bill
        ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
    JOIN customer_demographics cd_ship
        ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    JOIN date_dim d_promo_start
        ON p.p_start_date_sk = d_promo_start.d_date_sk
    JOIN date_dim d_promo_end
        ON p.p_end_date_sk = d_promo_end.d_date_sk
    JOIN store s
        ON s.s_closed_date_sk = d_sold.d_date_sk
    WHERE cs.cs_quantity > 0
    GROUP BY
        s.s_store_sk,
        s.s_store_name,
        s.s_city,
        s.s_state,
        p.p_promo_name,
        p.p_channel_email,
        d_sold.d_year,
        d_ship.d_year,
        cd_bill.cd_gender,
        cd_ship.cd_gender,
        d_promo_start.d_date,
        d_promo_end.d_date
)
SELECT
    a.s_store_name,
    a.s_city,
    a.s_state,
    a.p_promo_name,
    a.p_channel_email,
    a.sold_year,
    a.ship_year,
    a.bill_gender,
    a.ship_gender,
    a.promo_start_date,
    a.promo_end_date,
    a.total_net_paid,
    a.total_net_profit,
    a.distinct_orders,
    ROW_NUMBER() OVER (PARTITION BY a.s_store_name ORDER BY a.total_net_paid DESC) AS rank_by_store_sales,
    RANK() OVER (PARTITION BY a.bill_gender ORDER BY a.total_net_paid DESC) AS rank_by_gender_sales
FROM agg a
ORDER BY a.total_net_paid DESC
LIMIT 100
