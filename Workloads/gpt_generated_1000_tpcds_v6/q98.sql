WITH base AS (
    SELECT
        d.d_year,
        ca.ca_state,
        ca.ca_location_type,
        p.p_promo_name,
        r.r_reason_desc,
        w.w_warehouse_name,
        SUM(ss.ss_net_paid) AS total_store_sales,
        SUM(sr.sr_net_loss) AS total_store_returns_loss,
        SUM(ws.ws_net_paid) AS total_web_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS distinct_tickets,
        CASE WHEN SUM(ss.ss_net_paid) > 100000 THEN 'High' ELSE 'Low' END AS sales_category
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
        AND sr.sr_item_sk = ss.ss_item_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
        AND ws.ws_sold_time_sk = t.t_time_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE d.d_year = 2001
      AND t.t_sub_shift = 'morning'
      AND ca.ca_state = 'CA'
      AND p.p_discount_active = 'Y'
      AND r.r_reason_desc = 'Damaged'
      AND EXISTS (
          SELECT 1
          FROM promotion p2
          WHERE p2.p_promo_sk = ss.ss_promo_sk
            AND p2.p_cost > 500
      )
    GROUP BY d.d_year,
             ca.ca_state,
             ca.ca_location_type,
             p.p_promo_name,
             r.r_reason_desc,
             w.w_warehouse_name
)
SELECT
    d_year,
    ca_state,
    ca_location_type,
    p_promo_name,
    r_reason_desc,
    w_warehouse_name,
    total_store_sales,
    total_store_returns_loss,
    total_web_sales,
    distinct_tickets,
    sales_category,
    RANK() OVER (ORDER BY total_store_sales DESC) AS sales_rank,
    SUM(total_store_sales) OVER (
        PARTITION BY ca_state
        ORDER BY d_year
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_sales_by_state
FROM base
ORDER BY total_store_sales DESC
LIMIT 100
