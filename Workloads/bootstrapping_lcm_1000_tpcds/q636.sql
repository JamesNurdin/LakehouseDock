WITH sales_summary AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        s.s_city,
        s.s_state,
        p.p_promo_id,
        p.p_promo_name,
        d_common.d_year,
        d_common.d_month_seq,
        ca_bill.ca_city AS bill_city,
        ca_ship.ca_city AS ship_city,
        COUNT(DISTINCT cs.cs_order_number) AS order_cnt,
        SUM(cs.cs_net_paid) AS total_net_paid,
        SUM(cs.cs_net_profit) AS total_net_profit,
        AVG(cs.cs_ext_discount_amt) AS avg_discount,
        MIN(d_promo_start.d_date) AS promo_start_date,
        MAX(d_promo_end.d_date) AS promo_end_date
    FROM catalog_sales cs
    JOIN date_dim d_common
        ON cs.cs_sold_date_sk = d_common.d_date_sk
    JOIN store s
        ON s.s_closed_date_sk = d_common.d_date_sk
    JOIN date_dim d_ship
        ON cs.cs_ship_date_sk = d_ship.d_date_sk
    JOIN customer_address ca_bill
        ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
    JOIN customer_address ca_ship
        ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    JOIN date_dim d_promo_start
        ON p.p_start_date_sk = d_promo_start.d_date_sk
    JOIN date_dim d_promo_end
        ON p.p_end_date_sk = d_promo_end.d_date_sk
    WHERE cs.cs_sold_date_sk BETWEEN p.p_start_date_sk AND p.p_end_date_sk
      AND d_common.d_year = 2022
    GROUP BY
        s.s_store_id,
        s.s_store_name,
        s.s_city,
        s.s_state,
        p.p_promo_id,
        p.p_promo_name,
        d_common.d_year,
        d_common.d_month_seq,
        ca_bill.ca_city,
        ca_ship.ca_city
)
SELECT
    ss.*,
    ROW_NUMBER() OVER (PARTITION BY ss.s_store_id ORDER BY ss.total_net_paid DESC) AS sales_rank
FROM sales_summary ss
ORDER BY ss.total_net_paid DESC
LIMIT 100
