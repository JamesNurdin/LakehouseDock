WITH base AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        ca.ca_city,
        ca.ca_state,
        c.c_customer_sk,
        ss.ss_net_profit,
        ss.ss_net_paid,
        wr.wr_return_quantity,
        p.p_cost,
        t.t_hour
    FROM store_sales ss
    JOIN time_dim t
        ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    JOIN web_returns wr
        ON wr.wr_returning_customer_sk = c.c_customer_sk
    JOIN time_dim t_ret
        ON wr.wr_returned_time_sk = t_ret.t_time_sk
    WHERE s.s_state = 'CA'
      AND p.p_discount_active = 'Y'
      AND t.t_hour BETWEEN 9 AND 17
      AND c.c_preferred_cust_flag = 'Y'
      AND cd.cd_purchase_estimate > 5000
      AND EXISTS (
          SELECT 1
          FROM reason r
          WHERE r.r_reason_sk = wr.wr_reason_sk
            AND lower(r.r_reason_desc) LIKE '%warranty%'
      )
)
SELECT
    store_id,
    store_name,
    city,
    state,
    unique_customers,
    total_net_profit,
    total_net_paid,
    total_return_qty,
    avg_promo_cost,
    ROW_NUMBER() OVER (PARTITION BY state ORDER BY total_net_profit DESC) AS profit_rank_state,
    RANK() OVER (ORDER BY total_net_profit DESC) AS overall_profit_rank
FROM (
    SELECT
        s_store_id AS store_id,
        s_store_name AS store_name,
        ca_city AS city,
        ca_state AS state,
        COUNT(DISTINCT c_customer_sk) AS unique_customers,
        SUM(ss_net_profit) AS total_net_profit,
        SUM(ss_net_paid) AS total_net_paid,
        COUNT(wr_return_quantity) AS total_return_qty,
        AVG(p_cost) AS avg_promo_cost
    FROM base
    GROUP BY
        s_store_id,
        s_store_name,
        ca_city,
        ca_state
) agg
ORDER BY total_net_profit DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
