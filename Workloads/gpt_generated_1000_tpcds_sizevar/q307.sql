WITH ss_sample AS (
    SELECT *
    FROM store_sales
    TABLESAMPLE BERNOULLI (10)
),
joined AS (
    SELECT
        ss.ss_customer_sk,
        d.d_year,
        ca.ca_state,
        p.p_promo_name,
        ss.ss_net_paid,
        wr.wr_net_loss,
        inv.inv_quantity_on_hand
    FROM ss_sample ss
    JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    LEFT JOIN inventory inv
        ON d.d_date_sk = inv.inv_date_sk
    LEFT JOIN web_returns wr
        ON d.d_date_sk = wr.wr_returned_date_sk
        AND ss.ss_customer_sk = wr.wr_refunded_customer_sk
    WHERE d.d_year = 2001
      AND ca.ca_state = 'CA'
      AND p.p_discount_active = 'Y'
      AND inv.inv_warehouse_sk = 3
      AND ss.ss_quantity > 5
),
agg AS (
    SELECT
        d_year,
        ca_state,
        p_promo_name,
        COUNT(DISTINCT ss_customer_sk) AS unique_customers,
        SUM(ss_net_paid) AS total_sales,
        AVG(wr_net_loss) AS avg_return_loss,
        MAX(inv_quantity_on_hand) AS max_inventory_on_hand
    FROM joined
    GROUP BY d_year, ca_state, p_promo_name
)
SELECT
    d_year,
    ca_state,
    p_promo_name,
    unique_customers,
    total_sales,
    avg_return_loss,
    max_inventory_on_hand,
    ROW_NUMBER() OVER (ORDER BY total_sales DESC) AS sales_rank
FROM agg
ORDER BY total_sales DESC
LIMIT 100
