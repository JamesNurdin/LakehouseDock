WITH base AS (
    SELECT
        ss.ss_quantity,
        ss.ss_net_paid,
        ss.ss_sales_price,
        ss.ss_ticket_number,
        d.d_year,
        ca.ca_state,
        c.c_birth_month,
        p.p_promo_name,
        i.inv_warehouse_sk,
        i.inv_quantity_on_hand,
        wp.wp_type,
        c.c_customer_sk,
        d.d_date_sk
    FROM store_sales ss
    JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    JOIN inventory i
        ON i.inv_date_sk = d.d_date_sk
    JOIN web_page wp
        ON wp.wp_customer_sk = c.c_customer_sk
        AND wp.wp_creation_date_sk = d.d_date_sk
    WHERE d.d_year = 1999
      AND ca.ca_state = 'TX'
      AND c.c_birth_month = 5
      AND p.p_discount_active = 'Y'
      AND i.inv_warehouse_sk = 5
      AND wp.wp_type = 'home'
      AND i.inv_quantity_on_hand > 0
      AND NOT EXISTS (
          SELECT 1
          FROM web_page wp2
          WHERE wp2.wp_customer_sk = c.c_customer_sk
            AND wp2.wp_type = 'ads'
      )
),
agg AS (
    SELECT
        d_year,
        ca_state,
        c_birth_month,
        p_promo_name,
        SUM(ss_quantity) AS total_quantity,
        SUM(ss_net_paid) AS total_net_paid,
        COUNT(DISTINCT ss_ticket_number) AS distinct_tickets,
        AVG(ss_sales_price) AS avg_sales_price,
        MIN(ss_sales_price) AS min_sales_price,
        MAX(ss_sales_price) AS max_sales_price,
        RANK() OVER (PARTITION BY d_year ORDER BY SUM(ss_net_paid) DESC) AS net_paid_rank
    FROM base
    GROUP BY d_year, ca_state, c_birth_month, p_promo_name
)
SELECT
    a.d_year,
    a.ca_state,
    a.c_birth_month,
    a.p_promo_name,
    a.total_quantity,
    a.total_net_paid,
    a.distinct_tickets,
    a.avg_sales_price,
    a.min_sales_price,
    a.max_sales_price,
    a.net_paid_rank,
    m.metric_name,
    m.metric_value
FROM agg a
CROSS JOIN UNNEST(
    map(
        ARRAY['total_quantity','total_net_paid'],
        ARRAY[a.total_quantity, a.total_net_paid]
    )
) AS m(metric_name, metric_value)
ORDER BY a.total_net_paid DESC
LIMIT 100
