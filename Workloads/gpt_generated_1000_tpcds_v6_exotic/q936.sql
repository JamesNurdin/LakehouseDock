WITH sales_cte AS (
    SELECT
        c.c_customer_id,
        s.s_store_id,
        d.d_year,
        p.p_promo_id,
        'sale' AS txn_type,
        SUM(ss.ss_net_paid) AS amount,
        ROW_NUMBER() OVER (PARTITION BY d.d_year ORDER BY SUM(ss.ss_net_paid) DESC) AS yearly_rank
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN catalog_page cp ON cp.cp_start_date_sk = d.d_date_sk
    JOIN inventory inv ON inv.inv_date_sk = d.d_date_sk
    JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
        AND sr.sr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 1998
      AND s.s_state = 'CA'
      AND p.p_discount_active = 'Y'
    GROUP BY c.c_customer_id, s.s_store_id, d.d_year, p.p_promo_id
),
returns_cte AS (
    SELECT
        c.c_customer_id,
        s.s_store_id,
        d.d_year,
        p.p_promo_id,
        'return' AS txn_type,
        SUM(sr.sr_return_amt) AS amount,
        ROW_NUMBER() OVER (PARTITION BY d.d_year ORDER BY SUM(sr.sr_return_amt) DESC) AS yearly_rank
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    LEFT JOIN store_sales ss ON sr.sr_ticket_number = ss.ss_ticket_number
        AND ss.ss_sold_date_sk = d.d_date_sk
    LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    LEFT JOIN catalog_page cp ON cp.cp_end_date_sk = d.d_date_sk
    LEFT JOIN inventory inv ON inv.inv_date_sk = d.d_date_sk
    LEFT JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
    WHERE d.d_year = 1998
      AND s.s_state = 'CA'
      AND (p.p_discount_active = 'Y' OR p.p_discount_active IS NULL)
    GROUP BY c.c_customer_id, s.s_store_id, d.d_year, p.p_promo_id
)
SELECT
    combined.c_customer_id,
    combined.s_store_id,
    combined.d_year,
    combined.p_promo_id,
    combined.txn_type,
    combined.amount,
    combined.yearly_rank,
    ROW_NUMBER() OVER (PARTITION BY combined.d_year, combined.txn_type ORDER BY combined.amount DESC) AS overall_rank
FROM (
    SELECT * FROM sales_cte
    UNION ALL
    SELECT * FROM returns_cte
) AS combined
ORDER BY combined.d_year DESC, overall_rank
LIMIT 100
