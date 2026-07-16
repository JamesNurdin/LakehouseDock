WITH base_sales AS (
    SELECT ss.ss_customer_sk AS customer_sk, ss.ss_sold_date_sk AS date_sk, ss.ss_net_paid AS net_paid, ss.ss_net_profit AS net_profit, CAST(0 AS integer) AS source
    FROM store_sales ss
    UNION ALL
    SELECT cs.cs_bill_customer_sk AS customer_sk, cs.cs_sold_date_sk AS date_sk, cs.cs_net_paid AS net_paid, cs.cs_net_profit AS net_profit, CAST(1 AS integer) AS source
    FROM catalog_sales cs
    UNION ALL
    SELECT ws.ws_bill_customer_sk AS customer_sk, ws.ws_sold_date_sk AS date_sk, ws.ws_net_paid AS net_paid, ws.ws_net_profit AS net_profit, CAST(2 AS integer) AS source
    FROM web_sales ws
), monthly_agg AS (
    SELECT b.customer_sk,
           d.d_year,
           d.d_month_seq,
           SUM(b.net_paid) AS total_net_paid,
           SUM(b.net_profit) AS total_net_profit,
           COUNT(*) AS txn_count
    FROM base_sales b
    JOIN date_dim d ON b.date_sk = d.d_date_sk
    GROUP BY b.customer_sk, d.d_year, d.d_month_seq
), monthly_sales AS (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY customer_sk ORDER BY total_net_paid DESC) AS rank_by_spend
    FROM monthly_agg
), customer_info AS (
    SELECT c.c_customer_sk,
           CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
           c.c_preferred_cust_flag,
           cd.cd_gender AS gender,
           cd.cd_marital_status AS marital_status,
           hd.hd_buy_potential,
           COALESCE(ca.ca_city, 'UNKNOWN') AS city,
           COALESCE(ca.ca_state, 'UNKNOWN') AS state
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
), last_purchase AS (
    SELECT b.customer_sk,
           MAX(d.d_date) AS last_purchase_date
    FROM base_sales b
    JOIN date_dim d ON b.date_sk = d.d_date_sk
    GROUP BY b.customer_sk
)
SELECT
    ci.full_name,
    ci.c_preferred_cust_flag,
    ci.gender,
    ci.marital_status,
    ci.hd_buy_potential,
    ci.city,
    ci.state,
    ms.d_year,
    ms.d_month_seq,
    ms.total_net_paid,
    ms.total_net_profit,
    ms.txn_count,
    ms.rank_by_spend,
    lp.last_purchase_date,
    CASE
        WHEN ms.rank_by_spend = 1 THEN 'TOP_SPENDER'
        WHEN ms.total_net_paid > 10000 THEN 'HIGHVALUE'
        ELSE 'REGULAR'
    END AS customer_segment,
    COALESCE(recent_ret.r_reason_desc, 'NO_RETURN') AS recent_return_reason,
    COALESCE(ret_last_year.return_cnt_last_year, 0) AS return_cnt_last_year,
    (ms.total_net_profit / NULLIF(ms.total_net_paid, 0)) AS profit_margin,
    (ms.total_net_paid / NULLIF(ms.txn_count, 0)) AS avg_net_paid
FROM monthly_sales ms
JOIN customer_info ci ON ms.customer_sk = ci.c_customer_sk
LEFT JOIN last_purchase lp ON ms.customer_sk = lp.customer_sk
LEFT JOIN LATERAL (
    SELECT r.r_reason_desc
    FROM store_returns sr
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN date_dim d2 ON sr.sr_returned_date_sk = d2.d_date_sk
    WHERE sr.sr_customer_sk = ms.customer_sk
      AND d2.d_month_seq = ms.d_month_seq
    ORDER BY sr.sr_returned_date_sk DESC
    LIMIT 1
) AS recent_ret (r_reason_desc) ON TRUE
LEFT JOIN LATERAL (
    SELECT COUNT(*) AS return_cnt_last_year
    FROM store_returns sr
    JOIN date_dim d3 ON sr.sr_returned_date_sk = d3.d_date_sk
    WHERE sr.sr_customer_sk = ms.customer_sk
      AND d3.d_year = ms.d_year - 1
) AS ret_last_year (return_cnt_last_year) ON TRUE
WHERE ms.rank_by_spend <= 10
ORDER BY ms.d_year DESC, ms.d_month_seq ASC, ms.total_net_paid DESC
