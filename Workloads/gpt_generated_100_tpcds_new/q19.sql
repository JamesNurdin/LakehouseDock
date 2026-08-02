WITH cust_year_agg AS (
    SELECT
        c.c_customer_id,
        d_ret.d_year,
        SUM(sr.sr_return_amt) AS total_return_amt,
        SUM(sr.sr_net_loss) AS total_net_loss,
        COUNT(DISTINCT sr.sr_ticket_number) AS return_count,
        MAX(p.p_cost) AS max_promo_cost,
        MIN(ws.web_gmt_offset) AS min_gmt_offset
    FROM store_returns sr
    JOIN date_dim d_ret
        ON sr.sr_returned_date_sk = d_ret.d_date_sk
    JOIN customer c
        ON sr.sr_customer_sk = c.c_customer_sk
    JOIN promotion p
        ON p.p_start_date_sk = d_ret.d_date_sk
    JOIN web_site ws
        ON ws.web_open_date_sk = d_ret.d_date_sk
    JOIN catalog_page cp
        ON cp.cp_start_date_sk = d_ret.d_date_sk
    WHERE d_ret.d_year = 2001
      AND d_ret.d_weekend = 'N'
      AND p.p_promo_sk IN (14, 15)
      AND ws.web_state = 'WA'
      AND cp.cp_catalog_number BETWEEN 1 AND 20
      AND c.c_preferred_cust_flag = 'Y'
      AND sr.sr_customer_sk IN (
          SELECT c2.c_customer_sk
          FROM customer c2
          WHERE c2.c_birth_country = 'USA'
      )
    GROUP BY c.c_customer_id, d_ret.d_year
)
SELECT
    d_year,
    AVG(total_return_amt) AS avg_return_amt,
    SUM(total_net_loss) AS sum_net_loss,
    COUNT(*) AS customer_cnt
FROM cust_year_agg
GROUP BY d_year
ORDER BY d_year DESC
LIMIT 100
